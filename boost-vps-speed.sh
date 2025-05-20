#!/bin/bash
set -e

IFACE=$(ip -o -4 route show to default | awk '{print $5}')

cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 2097152
net.core.wmem_default = 2097152
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.udp_mem = 131072 262144 524288
net.ipv4.tcp_rmem = 4096 262144 33554432
net.ipv4.tcp_wmem = 4096 262144 33554432
net.ipv4.tcp_mem = 131072 262144 524288
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 0
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_frto = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_thin_linear_timeouts = 1
net.ipv4.tcp_thin_dupack = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_max_tw_buckets = 5000000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_synack_retries = 0
net.ipv4.tcp_syn_retries = 0
net.ipv4.tcp_retries1 = 1
net.ipv4.tcp_retries2 = 2
net.ipv4.udp_early_demux = 1
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 4096
net.core.optmem_max = 33554432
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 131072
net.netfilter.nf_conntrack_udp_timeout = 5
net.netfilter.nf_conntrack_udp_timeout_stream = 15
fs.file-max = 1048576
vm.swappiness = 0
vm.vfs_cache_pressure = 5
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.overcommit_memory = 1
vm.dirty_ratio = 1
vm.dirty_background_ratio = 0
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.route.gc_timeout = 10
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = cake
EOF

sysctl -p

cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

ulimit -n 1048576

tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root cake

ethtool -K $IFACE tso off gso off gro off 2>/dev/null || true
ip link set dev $IFACE txqueuelen 1000
optimal_mtu=$(ping -M do -s 1472 8.8.8.8 | grep -oP 'MTU \K\d+')
ip link set dev $IFACE mtu ${optimal_mtu:-1500}

iptables -t raw -F
iptables -t mangle -F
iptables -t nat -F
iptables -t filter -F
iptables -t raw -X
iptables -t mangle -X
iptables -t nat -X
iptables -t filter -X

iptables -t raw -A PREROUTING -p udp -j NOTRACK
iptables -t raw -A OUTPUT -p udp -j NOTRACK

echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 0 > /proc/sys/net/ipv4/tcp_no_metrics_save

echo 131072 > /proc/sys/kernel/threads-max
echo 131072 > /proc/sys/vm/max_map_count
echo 131072 > /proc/sys/kernel/pid_max

for i in /sys/class/net/$IFACE/queues/rx-*; do
  echo 0 > $i/rps_cpus 2>/dev/null || true
done

for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > $cpu 2>/dev/null || true
done

systemctl enable irqbalance
systemctl start irqbalance

ethtool -s $IFACE wol d 2>/dev/null || true

ping -i 0.2 -c 100 8.8.8.8

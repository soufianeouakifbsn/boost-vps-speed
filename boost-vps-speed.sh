#!/bin/bash
set -e
echo "🚀 بدء تطبيق أقصى تحسينات لتقليل الـ Ping"

IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 واجهة الشبكة: $IFACE"

# ضبط إعدادات النظام
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.udp_mem = 262144 524288 1048576
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mem = 262144 524288 1048576
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_thin_linear_timeouts = 1
net.ipv4.tcp_thin_dupack = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_frto = 2
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 20
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_retries1 = 2
net.ipv4.tcp_retries2 = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.route.gc_timeout = 10
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 32768
net.core.optmem_max = 67108864
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 131072
fs.file-max = 2097152
vm.swappiness = 0
vm.vfs_cache_pressure = 10
vm.overcommit_memory = 1
vm.dirty_ratio = 2
vm.dirty_background_ratio = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p

# limits
cat > /etc/security/limits.conf <<EOF
* soft nofile 2097152
* hard nofile 2097152
root soft nofile 2097152
root hard nofile 2097152
EOF
ulimit -n 2097152

# MTU detection
ping -c 1 -M do -s 1472 8.8.8.8 &> /dev/null && MTU=1500 || MTU=1350
ip link set dev $IFACE mtu $MTU
echo "📐 تم تعيين MTU إلى $MTU"

# Traffic Shaping
tc qdisc del dev $IFACE root 2>/dev/null || true
modprobe sch_cake &> /dev/null && tc qdisc add dev $IFACE root cake bandwidth 100mbit || tc qdisc add dev $IFACE root fq_codel
ip link set dev $IFACE txqueuelen 4000

# QoS & iptables
iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -N UDP_MARK || true
iptables -t mangle -A UDP_MARK -j DSCP --set-dscp-class EF
iptables -t mangle -A PREROUTING -p udp -j UDP_MARK
iptables -t mangle -A OUTPUT -p udp -j UDP_MARK
iptables -t mangle -A POSTROUTING -p udp -j TOS --set-tos Minimize-Delay

# Disable connection tracking for UDP
iptables -t raw -F
iptables -t raw -X
iptables -t raw -A PREROUTING -p udp -j NOTRACK
iptables -t raw -A OUTPUT -p udp -j NOTRACK

# IRQ و المعالج
systemctl enable irqbalance
systemctl start irqbalance

for i in /sys/class/net/$IFACE/queues/rx-*; do
  echo ffffffff > $i/rps_cpus 2>/dev/null || true
done

for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > $cpu 2>/dev/null || true
done

# kernel tweaks
echo 262144 > /proc/sys/kernel/threads-max
echo 262144 > /proc/sys/vm/max_map_count
echo 262144 > /proc/sys/kernel/pid_max

echo "✅ تم تطبيق أقصى تحسينات لتقليل الـ Ping بنجاح"
echo "🔄 يُفضل إعادة التشغيل الآن: sudo reboot"

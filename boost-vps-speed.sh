#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متقدمة لتثبيت وتقليل تقطع ping"

IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# إعدادات sysctl مع إضافة ضبط إضافي للـ MTU وتحسين TCP وUDP
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.udp_rmem_min = 262144
net.ipv4.udp_wmem_min = 262144
net.ipv4.udp_mem = 131072 262144 524288
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
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
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
net.ipv4.udp_early_demux = 1
net.core.netdev_max_backlog = 20000
net.core.somaxconn = 8192
net.core.optmem_max = 33554432
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 131072
net.netfilter.nf_conntrack_udp_timeout = 10
net.netfilter.nf_conntrack_udp_timeout_stream = 30
fs.file-max = 1048576
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.overcommit_memory = 1
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.route.gc_timeout = 15
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq_codel
EOF

sysctl -p

cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

ulimit -n 1048576

# حذف وضبط qdisc مع تحسين MTU و txqueuelen
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root fq_codel
ip link set dev $IFACE txqueuelen 1000
ip link set dev $IFACE mtu 1400

# تنظيف قواعد iptables وضبط QoS متقدم على UDP
iptables -t raw -F
iptables -t mangle -F
iptables -t nat -F
iptables -t filter -F
iptables -t raw -X
iptables -t mangle -X
iptables -t nat -X
iptables -t filter -X

iptables -t mangle -N UDP_MARK 2>/dev/null || true
iptables -t mangle -F UDP_MARK
iptables -t mangle -A UDP_MARK -j MARK --set-mark 1
iptables -t mangle -A UDP_MARK -j DSCP --set-dscp-class EF
iptables -t mangle -A PREROUTING -p udp -j UDP_MARK
iptables -t mangle -A OUTPUT -p udp -j UDP_MARK
iptables -t mangle -A POSTROUTING -p udp -j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p udp -j TOS --set-tos Minimize-Delay

iptables -t raw -A PREROUTING -p udp -j NOTRACK
iptables -t raw -A OUTPUT -p udp -j NOTRACK

# تعطيل بعض الإعدادات لتقليل التأخير
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 0 > /proc/sys/net/ipv4/tcp_no_metrics_save

# زيادة الحد الأقصى للخيوط والعمليات
echo 131072 > /proc/sys/kernel/threads-max
echo 131072 > /proc/sys/vm/max_map_count
echo 131072 > /proc/sys/kernel/pid_max

# تفعيل RPS لكل صفوف الاستقبال
for i in /sys/class/net/$IFACE/queues/rx-*; do
  echo 255 > $i/rps_cpus 2>/dev/null || true
done

# تعيين governor الخاص بالمعالج على performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > $cpu 2>/dev/null || true
done

systemctl enable irqbalance
systemctl start irqbalance

echo "✅ تم تطبيق تحسينات متقدمة لتثبيت ping"
echo "⚠️ يرجى إعادة تشغيل النظام لتفعيل جميع التغييرات: sudo reboot"

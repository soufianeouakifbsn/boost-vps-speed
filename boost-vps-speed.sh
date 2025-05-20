#!/bin/bash
set -e
echo "🚀 بدء تطبيق أقصى تحسينات الشبكة لتقليل تقلبات ping وتثبيته"

# كشف واجهة الشبكة الافتراضية
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 واجهة الشبكة المكتشفة: $IFACE"

# ضبط sysctl بأقصى إعدادات تحسين الشبكة والأداء
cat > /etc/sysctl.conf <<EOF
# Network buffers
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.udp_rmem_min = 262144
net.ipv4.udp_wmem_min = 262144
net.ipv4.udp_mem = 131072 262144 524288

# TCP memory and windows
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
net.ipv4.tcp_mem = 131072 262144 524288

# TCP features
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

# UDP optimizations
net.ipv4.udp_early_demux = 1

# Core network parameters
net.core.netdev_max_backlog = 30000
net.core.somaxconn = 8192
net.core.optmem_max = 33554432

# Connection tracking
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 131072
net.netfilter.nf_conntrack_udp_timeout = 10
net.netfilter.nf_conntrack_udp_timeout_stream = 30

# Filesystem and VM tuning
fs.file-max = 1048576
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.overcommit_memory = 1
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.max_map_count = 131072

# IP forwarding and port range
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535

# Route and rp_filter
net.ipv4.route.gc_timeout = 15
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0

# MTU probing and default qdisc
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq_codel
net.ipv4.tcp_adv_win_scale = 1
EOF

sysctl -p

# رفع الحد الأقصى للملفات المفتوحة لكل المستخدمين والجذر
cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

ulimit -n 1048576

# ضبط qdisc مع fq_codel المتقدم مع ECN على واجهة الشبكة
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root fq_codel limit 1500 ecn
ip link set dev $IFACE txqueuelen 1500
ip link set dev $IFACE mtu 1400

# تنظيف قواعد iptables وضبط QoS متقدم مع تحسين DSCP للـ UDP
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

# تعطيل timestamps لتقليل التأخير والتقلب
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 0 > /proc/sys/net/ipv4/tcp_no_metrics_save

# زيادة الحد الأقصى للخيوط والعمليات في النظام
echo 131072 > /proc/sys/kernel/threads-max
echo 131072 > /proc/sys/vm/max_map_count
echo 131072 > /proc/sys/kernel/pid_max

# تفعيل RPS لتوزيع استقبال الشبكة عبر جميع أنوية المعالج
for i in /sys/class/net/$IFACE/queues/rx-*; do
  echo 255 > $i/rps_cpus 2>/dev/null || true
done

# تعيين governor للمعالج على performance لضمان استجابة عالية
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > $cpu 2>/dev/null || true
done

# تشغيل irqbalance لتوزيع مقاطعات الأجهزة بشكل متوازن
if command -v systemctl &>/dev/null; then
  systemctl enable irqbalance
  systemctl start irqbalance
else
  service irqbalance start
fi

# ضبط DNS لخوادم سريعة ومستقرة لتقليل زمن الاستجابة
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

echo "✅ تم تطبيق جميع التحسينات المتقدمة القصوى لتقليل تقلبات ping"
echo "⚠️ يرجى إعادة تشغيل النظام لتفعيل كل التغييرات: sudo reboot"

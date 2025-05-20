#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متخصصة لتخفيض ping وتحقيق استقرار لاتصال UDP Custom مع HTTP Custom"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام مركزة فقط على تقليل زمن الاستجابة ========
cat > /etc/sysctl.conf <<EOF
# تقليل زمن الاستجابة ping بشكل جذري
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_mem = 65536 131072 262144
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 65536 131072 262144

# تعطيل معظم آليات تحكم الازدحام للتركيز على سرعة الاستجابة
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 0
net.ipv4.tcp_frto = 0
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_thin_linear_timeouts = 1
net.ipv4.tcp_thin_dupack = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3

# تقليل زمن توقف الاتصالات بشكل جذري
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 2
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_retries1 = 2
net.ipv4.tcp_retries2 = 3

# تقليل وقت معالجة حزم UDP
net.ipv4.udp_early_demux = 1
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 4096
net.core.optmem_max = 16777216
net.netfilter.nf_conntrack_max = 262144
net.netfilter.nf_conntrack_buckets = 65536
net.netfilter.nf_conntrack_udp_timeout = 10
net.netfilter.nf_conntrack_udp_timeout_stream = 30

# نظام الملفات والذاكرة
fs.file-max = 655350
vm.swappiness = 0
vm.vfs_cache_pressure = 10
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.overcommit_memory = 1
vm.dirty_ratio = 2
vm.dirty_background_ratio = 1

# تقليل زمن استجابة الشبكة
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.route.gc_timeout = 20
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = pfifo_fast
EOF

sysctl -p

# ======== إعداد حدود الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 500000
* hard nofile 500000
root soft nofile 500000
root hard nofile 500000
EOF

ulimit -n 500000

# ======== إزالة أي إعدادات شبكة سابقة لتجنب التعارض ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# ======== تطبيق إعدادات pfifo_fast لتقليل التأخير ========
tc qdisc add dev $IFACE root pfifo_fast
tc qdisc add dev $IFACE handle ffff: ingress

# تعيين إعدادات أساسية لتقليل التأخير
ip link set dev $IFACE txqueuelen 1000
ip link set dev $IFACE mtu 1400

# ======== إعداد iptables مع التركيز على سرعة معالجة البيانات ========
iptables -t raw -F
iptables -t mangle -F
iptables -t nat -F
iptables -t filter -F
iptables -t raw -X
iptables -t mangle -X
iptables -t nat -X
iptables -t filter -X

# إنشاء سلسلة خاصة لحزم UDP
iptables -t mangle -N UDP_MARK
iptables -t mangle -A UDP_MARK -j MARK --set-mark 1
iptables -t mangle -A UDP_MARK -j DSCP --set-dscp-class EF

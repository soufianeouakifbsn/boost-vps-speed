#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات لتقليل Ping ومنع التقطعات لاتصال UDP Custom مع HTTP Custom App"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام لخفض Ping ========
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.udp_mem = 65536 131072 33554432
net.ipv4.udp_so_reuseport = 1
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 8192
net.core.optmem_max = 25165824
net.netfilter.nf_conntrack_max = 786432
net.netfilter.nf_conntrack_buckets = 196608
net.netfilter.nf_conntrack_udp_timeout = 90
net.netfilter.nf_conntrack_udp_timeout_stream = 240
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.core.default_qdisc = fq_codel
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 16384
fs.file-max = 2097152
vm.swappiness = 5
vm.vfs_cache_pressure = 30
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.overcommit_memory = 1
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_max_tw_buckets = 2000000
EOF

sysctl -p

# ======== إعداد حدود الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 786432
* hard nofile 786432
root soft nofile 786432
root hard nofile 786432
EOF

ulimit -n 786432

# ======== إزالة إعدادات الشبكة القديمة ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# ======== HTB + FQ_CODEL لخفض التقطعات وتحسين الاستقرار ========
tc qdisc add dev $IFACE root handle 1: htb default 10
tc class add dev $IFACE parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit
tc class add dev $IFACE parent 1:1 classid 1:10 htb rate 900mbit ceil 1000mbit prio 0
tc class add dev $IFACE parent 1:1 classid 1:20 htb rate 100mbit ceil 300mbit prio 1
tc filter add dev $IFACE parent 1: protocol ip prio 1 handle 10 fw flowid 1:10
tc qdisc add dev $IFACE parent 1:10 handle 10: fq_codel
tc qdisc add dev $IFACE parent 1:20 handle 20: fq_codel

# ======== تحسين الطابور والإرسال ========
ip link set dev $IFACE txqueuelen 1000
ip link set dev $IFACE mtu 1500

# ======== iptables تعليم حزم UDP فقط ========
iptables -t mangle -F
ip6tables -t mangle -F
iptables -t mangle -N UDPMARKING 2>/dev/null || true
iptables -t mangle -F UDPMARKING
iptables -t mangle -D OUTPUT -p udp -j UDPMARKING 2>/dev/null || true
iptables -t mangle -A UDPMARKING -j MARK --set-mark 10
iptables -t mangle -A OUTPUT -p udp -j UDPMARKING

# ======== موارد النظام الإضافية ========
echo 65536 > /proc/sys/kernel/threads-max
echo 65536 > /proc/sys/vm/max_map_count
echo 65536 > /proc/sys/kernel/pid_max

# ======== خدمة systemd لتطبيق الإعدادات عند الإقلاع ========
cat > /etc/systemd/system/udp-custom-optimize.service <<EOF
[Unit]
Description=UDP Custom Advanced Optimization Service with Low Latency
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'IFACE=\$(ip -o -4 route show to default | awk "{print \$5}"); \
tc qdisc del dev \$IFACE root 2>/dev/null || true; \
tc qdisc add dev \$IFACE root handle 1: htb default 10; \
tc class add dev \$IFACE parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit; \
tc class add dev \$IFACE parent 1:1 classid 1:10 htb rate 900mbit ceil 1000mbit prio 0; \
tc class add dev \$IFACE parent 1:1 classid 1:20 htb rate 100mbit ceil 300mbit prio 1; \
tc filter add dev \$IFACE parent 1: protocol ip prio 1 handle 10 fw flowid 1:10; \
tc qdisc add dev \$IFACE parent 1:10 handle 10: fq_codel; \
tc qdisc add dev \$IFACE parent 1:20 handle 20: fq_codel; \
iptables -t mangle -N UDPMARKING 2>/dev/null || true; \
iptables -t mangle -F UDPMARKING; \
iptables -t mangle -D OUTPUT -p udp -j UDPMARKING 2>/dev/null || true; \
iptables -t mangle -A UDPMARKING -j MARK --set-mark 10; \
iptables -t mangle -A OUTPUT -p udp -j UDPMARKING; \
ip link set dev \$IFACE txqueuelen 1000;'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom-optimize.service

echo "✅ تم تطبيق تحسينات تقليل Ping ومنع التقطعات بنجاح"
echo "⚠️ أعد تشغيل النظام لتفعيل جميع التحسينات: sudo reboot"

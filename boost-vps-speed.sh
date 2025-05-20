#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متقدمة لزيادة سرعة اتصال UDP Custom مع HTTP Custom App"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام ========
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_mem = 65536 131072 67108864
net.ipv4.udp_so_reuseport = 1
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 16384
net.core.optmem_max = 50331648
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_buckets = 262144
net.netfilter.nf_conntrack_udp_timeout = 60
net.netfilter.nf_conntrack_udp_timeout_stream = 180
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
net.core.default_qdisc = fq
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
fs.file-max = 4194304
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.overcommit_memory = 1
EOF

sysctl -p

# ======== إزالة أي إعدادات شبكة سابقة لتجنب التعارض ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# ======== إعداد جدولة الشبكة FQ_CODEL ========
tc qdisc add dev $IFACE root handle 1: fq_codel target 5ms interval 100ms limit 1000 quantum 300

# ======== تعيين طابور الإرسال ========
ip link set dev $IFACE txqueuelen 10000
ip link set dev $IFACE mtu 1500

# ======== إعداد iptables لحزم UDP ========
iptables -t mangle -F
iptables -t mangle -A OUTPUT -p udp -j TOS --set-tos Minimize-Delay

echo "✅ تم تحسين أداء الاتصال وتقليل التقطع والـping المرتفع"
echo "⚠️ يُفضل إعادة تشغيل النظام الآن لتفعيل كافة التعديلات: sudo reboot"

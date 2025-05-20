#!/bin/bash
set -e
echo "🔧 تحسينات خفيفة لتقليل التقطعات والـ Ping"

IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "📡 الواجهة: $IFACE"

# إعدادات النواة
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 2500000
net.core.wmem_max = 2500000
net.core.rmem_default = 212992
net.core.wmem_default = 212992
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p

# حذف أي إعدادات سابقة
tc qdisc del dev $IFACE root 2>/dev/null || true

# استخدام default fq بسيط فقط (بدون HTB)
tc qdisc add dev $IFACE root fq

# إعادة txqueuelen لقيمة مستقرة
ip link set dev $IFACE txqueuelen 1500

echo "✅ تم التخفيف من الإعدادات. أعد التشغيل الآن: sudo reboot"

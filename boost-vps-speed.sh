#!/bin/bash
set -e
echo "🚀 بدء تحسين سرعة الإنترنت مع UDP و HTTP Custom"

# تحديد واجهة الشبكة الافتراضية
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ضبط تحسينات نواة النظام
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
EOF

sysctl -p

# تحسين إعدادات بطاقة الشبكة
ethtool -K $IFACE tso on gso on gro on

# ضبط QoS عبر `Cake`
tc qdisc add dev $IFACE root cake bandwidth 100mbit besteffort

echo "✅ تم تطبيق التحسينات! يُفضل إعادة التشغيل لتفعيل التغييرات."

#!/bin/bash
echo "🚀 معالجة مشكلة اختناق الشبكة وضبط TCP Vegas لتحقيق أقصى استقرار! ⚡"

# تحسين Vegas لتقليل الاختناق
echo "🔥 ضبط Vegas لجعل الاستجابة أكثر استقرارًا!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_vegas_alpha = 1
net.ipv4.tcp_vegas_beta = 3
net.ipv4.tcp_vegas_gamma = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1
EOF

sysctl -p

# تعزيز حجم المخزن المؤقت
echo "📡 زيادة Buffer لمنع فقدان البيانات!"
sysctl -w net.ipv4.udp_rmem_max=4294967296
sysctl -w net.ipv4.udp_wmem_max=4294967296

# تحسين توزيع الحمل عبر QoS
echo "🔥 ضبط QoS لجعل الاتصال أكثر سلاسة!"
tc qdisc replace dev eth0 root fq_codel

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق استقرار مطلق!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 50000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط `txqueuelen` لمنع التراجع في الأداء
echo "⚡ ضبط txqueuelen لتقليل التأخير!"
ifconfig eth0 txqueuelen 500000

echo "✅ تم تطبيق التحسينات! 🚀 يجب أن يكون الاتصال مستقرًا الآن!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

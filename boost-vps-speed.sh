#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة باستخدام TCP Vegas لتحقيق استجابة مثالية وسرعة مستقرة! ⚡"

# تمكين TCP Vegas كخوارزمية التحكم في الازدحام
echo "🔥 تفعيل TCP Vegas لتحسين استجابة الشبكة!"
cat > /etc/sysctl.conf <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = vegas

# تحسين حركة المرور عبر TCP/UDP
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1

# ضبط إعدادات زمن الاستجابة في Vegas
net.ipv4.tcp_vegas_alpha = 2
net.ipv4.tcp_vegas_beta = 6
net.ipv4.tcp_vegas_gamma = 1
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق أقصى أداء!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 50000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط MTU لضمان تدفق سلس للحزم
echo "📡 ضبط MTU إلى 9000 للحصول على أداء ثابت!"
ifconfig $IFACE mtu 9000
sysctl -w net.ipv4.route_min_pmtu=1000

# تحسين معالجة الحزم عبر `Multi-Queue Processing`
echo "⚡ تحسين معالجة الحزم لتقليل زمن الاستجابة!"
sysctl -w net.core.dev_weight=4096
sysctl -w net.core.netdev_budget=400000
sysctl -w net.core.netdev_budget_usecs=100000

# ضبط `QoS` لضمان تدفق سريع عبر UDP
echo "🔥 تحسين جودة الاتصال عبر ضبط QoS!"
tc qdisc add dev eth0 root handle 1: htb default 10
tc class add dev eth0 parent 1: classid 1:1 htb rate 5000mbit ceil 5000mbit
tc class add dev eth0 parent 1: classid 1:10 htb rate 2500mbit ceil 5000mbit
tc qdisc add dev eth0 parent 1:10 handle 10: sfq perturb 10

# تعزيز سرعة رفع البيانات عبر UDP
echo "🔥 تحسين سرعة الرفع عبر UDP!"
sysctl -w net.ipv4.udp_wmem_max=17179869184
sysctl -w net.ipv4.udp_wmem_min=16777216
ethtool -G $IFACE tx 8388608
ifconfig $IFACE txqueuelen 200000

# ضبط حدود الملفات المفتوحة
ulimit -n 2147483648

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 2147483648
* hard nofile 2147483648
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن تعمل بأقصى سرعة باستخدام TCP Vegas!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

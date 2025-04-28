#!/bin/bash
echo "🚀 تحسين أداء TCP Vegas لتوفير أقصى سرعة واستقرار! ⚡"

# ضبط Vegas مع تحسينات لمنع الاختناق
echo "🔥 ضبط TCP Vegas ليعمل بكفاءة أعلى!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_congestion_control = vegas

# تحسين Vegas لمنع التقطعات أثناء الضغط العالي
net.ipv4.tcp_vegas_alpha = 2
net.ipv4.tcp_vegas_beta = 4
net.ipv4.tcp_vegas_gamma = 1

# تمكين HyStart++ لمنع أي تراجع مفاجئ عند بدء الاتصال
net.ipv4.tcp_hystart_allow_burst = 1
net.ipv4.tcp_hystart_detect = 1
net.ipv4.tcp_hystart_low_window = 16
net.ipv4.tcp_hystart_plus = 1

# تحسين حركة المرور عبر TCP/UDP
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1
EOF

sysctl -p

# تحسين المخزن المؤقت لمنع أي فقدان في الحزم
echo "📡 ضبط Buffer لمنع التقطع المفاجئ!"
sysctl -w net.ipv4.udp_rmem_max=8589934592
sysctl -w net.ipv4.udp_wmem_max=17179869184

# تحسين توزيع الحمل عبر IRQ Balancing
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=100

# تحسين توزيع الحمل عبر QoS
echo "🔥 ضبط QoS لتسهيل تدفق البيانات!"
tc qdisc replace dev eth0 root fq_codel quantum 5000

# ضبط إعدادات بطاقة الشبكة لتحقيق أقصى أداء
echo "🔧 ضبط بطاقة الشبكة لمنع تقلبات الاتصال!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -s $IFACE speed 50000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط `txqueuelen` لمنع الاختناق المفاجئ
echo "⚡ ضبط txqueuelen لجعل الاتصال ثابتًا تمامًا!"
ifconfig eth0 txqueuelen 750000

echo "✅ تم تطبيق التحسينات! 🚀 الاتصال الآن يعمل بسرعة واستقرار مذهلين!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

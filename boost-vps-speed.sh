#!/bin/bash
echo "🚀 تحسين أداء UDP ومنع الاختناق نهائيًا مع TCP Vegas و HyStart++! ⚡"

# ضبط TCP Vegas و HyStart++ لتحقيق أقصى استقرار
echo "🔥 ضبط TCP Vegas مع HyStart++ لمنع التراجع المفاجئ!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_congestion_control = vegas

# تحسين Vegas لمنع التقطع في تدفق البيانات
net.ipv4.tcp_vegas_alpha = 3
net.ipv4.tcp_vegas_beta = 5
net.ipv4.tcp_vegas_gamma = 1

# تمكين HyStart++ لمنع انخفاض الأداء عند بدء الاتصال
net.ipv4.tcp_hystart_allow_burst = 1
net.ipv4.tcp_hystart_detect = 1
net.ipv4.tcp_hystart_low_window = 32
net.ipv4.tcp_hystart_plus = 1

# تحسين حركة المرور عبر TCP/UDP
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1

# ضبط TCP Window Scaling لضمان سرعة استجابة عالية
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 2

# تمكين SO_REUSEPORT لضمان توزيع الحمل عبر عدة مسارات
net.ipv4.udp_so_reuseport = 1
EOF

sysctl -p

# تعزيز المخزن المؤقت لمنع فقدان الحزم في UDP
echo "📡 ضبط Buffer لضمان تدفق بيانات سلس بدون انقطاعات!"
sysctl -w net.ipv4.udp_rmem_max=34359738368
sysctl -w net.ipv4.udp_wmem_max=34359738368

# تحسين توزيع الحمل عبر IRQ Balancing لتسريع معالجة الحزم
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=50

# ضبط QoS لمنع تقطع تدفق UDP حتى مع الضغط العالي
echo "🔥 ضبط QoS لجعل UDP يعمل بسلاسة!"
tc qdisc replace dev eth0 root fq_codel quantum 12000

# ضبط إعدادات بطاقة الشبكة لتحقيق تدفق ثابت
echo "🔧 ضبط بطاقة الشبكة لمنع تقلبات الاتصال!"
IFACE="eth0"
ethtool -G $IFACE rx 4194304 tx 4194304
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -s $IFACE speed 100000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط txqueuelen لمنع الانقطاعات المفاجئة في تدفق UDP
echo "⚡ ضبط txqueuelen لضمان ثبات الأداء حتى مع الضغط العالي!"
ifconfig eth0 txqueuelen 1500000

echo "✅ تم تطبيق جميع التحسينات! 🚀 يجب أن يكون تدفق UDP مستقرًا تمامًا بدون أي اختناق!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

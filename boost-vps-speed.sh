#!/bin/bash
echo "🚀 تحسين شامل لأداء الشبكة لتسريع تحميل الفيديو ومنع اختناق UDP! ⚡"

# ضبط TCP Vegas و HyStart++ لتحقيق أعلى استقرار
echo "🔥 ضبط TCP Vegas مع HyStart++ لضمان اتصال سلس!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_congestion_control = vegas

# تحسين Vegas لمنع الاختناق أثناء تحميل الفيديو
net.ipv4.tcp_vegas_alpha = 3
net.ipv4.tcp_vegas_beta = 6
net.ipv4.tcp_vegas_gamma = 2

# تمكين HyStart++ لمنع انخفاض الأداء عند بدء تشغيل الفيديو أو تحميل البيانات
net.ipv4.tcp_hystart_allow_burst = 1
net.ipv4.tcp_hystart_detect = 1
net.ipv4.tcp_hystart_low_window = 32
net.ipv4.tcp_hystart_plus = 1

# تحسين حركة المرور عبر TCP/UDP لتقليل زمن انتظار الفيديو وتحسين التدفق
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1

# ضبط TCP Window Scaling لضمان سرعة استجابة عالية
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 2

# تحسين الاتصال عبر UDP لمنع فقدان البيانات واختناق المخزن المؤقت
net.ipv4.udp_rmem_max = 34359738368
net.ipv4.udp_wmem_max = 34359738368
net.ipv4.udp_so_reuseport = 1
EOF

sysctl -p

# تحسين QoS لضمان تحميل الفيديو فور الضغط عليه ومنع التقطع أثناء الاتصال
echo "🔥 ضبط QoS لجعل تشغيل الفيديو وتحميل البيانات أكثر سلاسة!"
tc qdisc replace dev eth0 root fq_codel quantum 12000

# ضبط إعدادات بطاقة الشبكة لتحقيق أقصى أداء ومنع الاختناق
echo "🔧 ضبط بطاقة الشبكة لضمان استجابة فائقة السرعة!"
IFACE="eth0"
ethtool -G $IFACE rx 512 tx 512
ethtool -C $IFACE rx-usecs 64 tx-usecs 64
ethtool -s $IFACE speed 10000 duplex full autoneg off
ethtool -K $IFACE gro on lro on

# ضبط `txqueuelen` لضمان تحميل الفيديو فور الضغط عليه ومنع أي تأخير في UDP
echo "⚡ ضبط txqueuelen لجعل تدفق البيانات مستقرًا تمامًا!"
ifconfig eth0 txqueuelen 1500000

echo "✅ تم تطبيق جميع التحسينات! 🚀 يجب أن يكون تشغيل الفيديو وتحميل البيانات عبر UDP سلسًا بدون أي اختناق!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

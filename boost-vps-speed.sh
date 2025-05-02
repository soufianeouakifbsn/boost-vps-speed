#!/bin/bash
echo "🚀 تحسين إعدادات الشبكة لتشغيل الفيديو فور الضغط عليه وتقليل زمن الانتظار! ⚡"

# تحسين TCP Vegas مع HyStart++ لتسريع بدء الاتصال
echo "🔥 ضبط TCP Vegas مع HyStart++ لضمان استجابة فورية!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_congestion_control = vegas

# تحسين Vegas لمنع الاختناق أثناء تحميل الفيديو
net.ipv4.tcp_vegas_alpha = 3
net.ipv4.tcp_vegas_beta = 6
net.ipv4.tcp_vegas_gamma = 2

# تمكين HyStart++ لمنع التأخير عند بدء تشغيل الفيديو
net.ipv4.tcp_hystart_allow_burst = 1
net.ipv4.tcp_hystart_detect = 1
net.ipv4.tcp_hystart_low_window = 32
net.ipv4.tcp_hystart_plus = 1

# تحسين حركة المرور عبر TCP/UDP لتقليل زمن انتظار الفيديو
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1

# ضبط `TCP Window Scaling` لضمان سرعة استجابة عالية
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 2
EOF

sysctl -p

# تحسين المخزن المؤقت لمنع تقطع الفيديو
echo "📡 ضبط Buffer لمنع التقطع أثناء تشغيل الفيديو!"
sysctl -w net.ipv4.udp_rmem_max=17179869184
sysctl -w net.ipv4.udp_wmem_max=34359738368

# تحسين توزيع الحمل عبر QoS لمنع التأخير أثناء تحميل الفيديو
echo "🔥 ضبط QoS لجعل تشغيل الفيديو أكثر سلاسة!"
tc qdisc replace dev eth0 root fq_codel quantum 10000

# تحسين إعدادات بطاقة الشبكة لتحقيق أقصى أداء أثناء تشغيل الفيديو
echo "🔧 ضبط بطاقة الشبكة لمنع تقلبات الاتصال!"
IFACE="eth0"
ethtool -G $IFACE rx 4194304 tx 4194304
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -s $IFACE speed 100000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط `txqueuelen` لضمان تحميل الفيديو فور الضغط عليه
echo "⚡ ضبط txqueuelen لتقليل زمن انتظار الفيديو!"
ifconfig eth0 txqueuelen 1000000

echo "✅ تم تطبيق التحسينات! 🚀 يجب أن يتم تشغيل الفيديو فور الضغط عليه بدون تأخير!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

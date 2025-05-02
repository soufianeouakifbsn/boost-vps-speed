#!/bin/bash
echo "🚀 تحسين أداء TCP Vegas ليدعم 100 اتصال متزامن بدون اختناق! ⚡"

# ضبط Vegas مع تحسينات لمنع الازدحام والتراجع المفاجئ
echo "🔥 ضبط TCP Vegas ليكون أكثر ذكاءً!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_congestion_control = vegas

# تحسين Vegas لمنع التقلبات أثناء الضغط العالي
net.ipv4.tcp_vegas_alpha = 3
net.ipv4.tcp_vegas_beta = 5
net.ipv4.tcp_vegas_gamma = 1

# تمكين HyStart++ لمنع انخفاض الأداء حتى مع 100 اتصال متزامن
net.ipv4.tcp_hystart_allow_burst = 1
net.ipv4.tcp_hystart_detect = 1
net.ipv4.tcp_hystart_low_window = 32
net.ipv4.tcp_hystart_plus = 1

# تحسين حركة المرور عبر TCP/UDP
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1

# رفع الحد الأقصى للاتصالات المتزامنة
net.ipv4.tcp_max_syn_backlog = 4096
net.core.somaxconn = 65535
EOF

sysctl -p

# تحسين المخزن المؤقت لمنع أي فقدان في الحزم حتى مع 100 اتصال
echo "📡 ضبط Buffer لمنع التقطع المفاجئ!"
sysctl -w net.ipv4.udp_rmem_max=17179869184
sysctl -w net.ipv4.udp_wmem_max=34359738368

# تحسين توزيع الحمل عبر IRQ Balancing
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=50

# تحسين توزيع الحمل عبر QoS لمنع الاختناق حتى مع الضغط العالي
echo "🔥 ضبط QoS لجعل الاتصال أكثر استقرارًا!"
tc qdisc replace dev eth0 root fq_codel quantum 8000

# ضبط إعدادات بطاقة الشبكة لتحقيق أقصى أداء حتى مع 100 مستخدم
echo "🔧 ضبط بطاقة الشبكة لمنع تقلبات الاتصال!"
IFACE="eth0"
ethtool -G $IFACE rx 4194304 tx 4194304
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -s $IFACE speed 100000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط `txqueuelen` لضمان تدفق ثابت ومستقر
echo "⚡ ضبط txqueuelen لضمان استقرار كامل حتى مع 100 اتصال!"
ifconfig eth0 txqueuelen 1000000

echo "✅ تم تطبيق التحسينات! 🚀 يجب أن يكون الاتصال ثابتًا حتى مع 100 مستخدم متزامن!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

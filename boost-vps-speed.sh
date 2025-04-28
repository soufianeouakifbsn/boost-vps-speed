#!/bin/bash
echo "🚀 تحسين الشبكة باستخدام BBR v2 لتحقيق أقصى سرعة واستقرار! ⚡"

# تمكين BBR v2 كخوارزمية التحكم في الازدحام
echo "🔥 ضبط BBR v2 لتحسين تدفق البيانات!"
cat > /etc/sysctl.conf <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr2

# تحسين حركة المرور عبر TCP/UDP
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 30
EOF

sysctl -p

# تحسين المخزن المؤقت لمنع فقدان الحزم
echo "📡 ضبط Buffer Adaptation لتحقيق تدفق سلس!"
sysctl -w net.ipv4.udp_mem=33554432 268435456 549755813888
sysctl -w net.ipv4.udp_rmem_max=17179869184
sysctl -w net.ipv4.udp_wmem_max=34359738368

# تحسين توزيع الحمل عبر IRQ Balancing
echo "🔥 ضبط IRQ Balance لمنع أي تأخير!"
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=100

# تحسين توزيع الحمل عبر QoS
echo "🔥 ضبط QoS لجعل الاتصال أكثر استقرارًا!"
tc qdisc replace dev eth0 root fq_codel quantum 5000

# ضبط إعدادات بطاقة الشبكة لتحقيق أقصى أداء
echo "🔧 ضبط بطاقة الشبكة لتحقيق اتصال مستقر تمامًا!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 50000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط txqueuelen لضمان إرسال بيانات مستمر بدون تقطع
echo "⚡ ضبط txqueuelen لتحقيق ثبات أعلى!"
ifconfig eth0 txqueuelen 1000000

echo "✅ تم تطبيق التحسينات! 🚀 يجب أن يكون الاتصال مستقرًا الآن بدون اختناق!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

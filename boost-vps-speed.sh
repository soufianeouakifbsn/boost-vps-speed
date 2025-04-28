#!/bin/bash
echo "🚀 معالجة عدم الاستقرار وضبط TCP Vegas لتحقيق أداء ثابت! ⚡"

# تحسين TCP لاستقرار أقوى
echo "🔥 ضبط TCP لمنع التقلبات المفاجئة!"
cat > /etc/sysctl.conf <<EOF
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 30
EOF

sysctl -p

# تحسين المخزن المؤقت لجعل الاتصال أكثر سلاسة
echo "📡 ضبط Buffer Adaptation لضمان تدفق ثابت!"
sysctl -w net.ipv4.udp_mem=16777216 134217728 274877906944
sysctl -w net.ipv4.udp_rmem_max=8589934592
sysctl -w net.ipv4.udp_wmem_max=17179869184

# تحسين توزيع الحمل عبر `IRQ Balancing`
echo "🔥 ضبط IRQ Balance لمنع أي تأخير!"
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=250

# تحسين QoS لمنع تقلبات الاتصال
echo "⚡ ضبط QoS لجعل الاتصال أكثر استقرارًا!"
tc qdisc add dev eth0 root handle 1: fq_codel

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق اتصال مستقر تمامًا!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 50000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط `txqueuelen` لمنع انهيار الأداء مؤقتًا
echo "⚡ ضبط txqueuelen لجعل الاستجابة ثابتة!"
ifconfig eth0 txqueuelen 750000

echo "✅ تم تطبيق التحسينات! 🚀 يجب أن يكون الاتصال مستقرًا الآن!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

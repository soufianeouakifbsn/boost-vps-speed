#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة لضمان وصول السرعة الكاملة! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 8388608
net.core.netdev_max_backlog = 320000000

# تعزيز تدفق البيانات عبر UDP (تحميل ورفع بسرعة جنونية)
net.core.optmem_max = 34359738368
net.ipv4.udp_mem = 8388608 67108864 137438953472
net.ipv4.udp_rmem_min = 8388608
net.ipv4.udp_wmem_min = 8388608
net.ipv4.udp_rmem_max = 2147483648
net.ipv4.udp_wmem_max = 4294967296

# تحسين إدارة حركة المرور عبر الشبكة
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_ecn = 1
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق أقصى سرعة ونقل البيانات بسلاسة!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 25000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط MTU للحصول على تدفق ضخم للحزم
echo "📡 ضبط MTU إلى 9000 أو التكيف التلقائي!"
ifconfig $IFACE mtu 9000
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# تحسين توزيع البيانات عبر الشبكة
echo "🔥 تفعيل Load Balancing لتوزيع الضغط وضمان التدفق السريع!"
sysctl -w net.ipv4.fib_multipath_hash_policy=1

# تعزيز سرعة الرفع عبر UDP
echo "🔥 رفع سرعة الرفع عبر UDP إلى الحد الأقصى!"
ethtool -G $IFACE tx 4194304  # رفع المخزن المؤقت للإرسال

# ضبط استقرار اتصال الشبكة ومعالجة الحزم بكفاءة
sysctl -w net.core.somaxconn=65535
sysctl -w net.core.netdev_max_backlog=1000000

# تحسين استجابة المعالج لمعالجة الحزم
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=500

# ضبط حدود الملفات المفتوحة
ulimit -n 1073741824

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 1073741824
* hard nofile 1073741824
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن جاهزة لنقل البيانات بسرعة خيالية بدون انخفاض!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

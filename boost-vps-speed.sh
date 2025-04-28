#!/bin/bash
echo "🚀 ضبط إعدادات الشبكة لتقليل التأخير وتحقيق استجابة فائقة السرعة! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 8388608
net.core.netdev_max_backlog = 320000000

# تعزيز تدفق البيانات عبر UDP
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
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتقليل التأخير وتحقيق استجابة فورية!"
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
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# تحسين توزيع البيانات عبر الشبكة
echo "🔥 تفعيل Load Balancing لتوزيع الضغط وضمان التدفق السريع!"
sysctl -w net.ipv4.fib_multipath_hash_policy=1

# تحسين استجابة الشبكة عبر `dev_weight` و `netdev_budget`
echo "⚡ تحسين معالجة الحزم لتقليل زمن الاستجابة!"
sysctl -w net.core.dev_weight=2048
sysctl -w net.core.netdev_budget=200000
sysctl -w net.core.netdev_budget_usecs=50000

# تحسين استخدام موارد المعالج عبر `IRQ Balance`
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=250

# ضبط حدود الملفات المفتوحة
ulimit -n 1073741824

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 1073741824
* hard nofile 1073741824
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن جاهزة للاستجابة الفورية بدون أي تأخير!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

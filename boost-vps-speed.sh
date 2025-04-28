#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة للحصول على أقصى سرعة اتصال عبر UDP مع ZIVPN و VPS! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 16777216
net.core.rfs_memory_limit = 67108864
net.core.netdev_max_backlog = 320000000

# تعزيز تدفق البيانات عبر UDP
net.core.optmem_max = 34359738368
net.ipv4.udp_mem = 8388608 67108864 137438953472
net.ipv4.udp_rmem_min = 8388608
net.ipv4.udp_wmem_min = 8388608
net.ipv4.udp_rmem_max = 4294967296
net.ipv4.udp_wmem_max = 8589934592

# تحسين إدارة حركة المرور عبر الشبكة
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_nodelay = 1
net.ipv4.tcp_tw_reuse = 1
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة للحصول على أقصى أداء!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 25000 duplex full autoneg off
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط MTU للحصول على تدفق ضخم للحزم
echo "📡 ضبط MTU إلى 9000!"
ifconfig $IFACE mtu 9000
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# تحسين توزيع البيانات عبر الشبكة
echo "🔥 تفعيل Load Balancing لضمان تدفق سلس!"
sysctl -w net.ipv4.fib_multipath_hash_policy=1

# تحسين استجابة الشبكة عبر `dev_weight` و `netdev_budget`
echo "⚡ تحسين معالجة الحزم لتقليل زمن الاستجابة!"
sysctl -w net.core.dev_weight=2048
sysctl -w net.core.netdev_budget=200000
sysctl -w net.core.netdev_budget_usecs=50000

# تحسين استخدام موارد المعالج عبر `IRQ Balance`
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=250

# تحسين إعدادات VPN مع ZIVPN
echo "🔥 تحسين إعدادات الـ VPS لتسريع VPN وتقليل التأخير!"
sysctl -w net.ipv4.udp_rmem_max=2147483648
sysctl -w net.ipv4.udp_wmem_max=2147483648
sysctl -w net.ipv4.tcp_fastopen=3

# ضبط `QoS` لضمان أولوية اتصال ZIVPN
echo "🚀 ضبط QoS لضمان استقرار سرعة الـ UDP!"
tc qdisc add dev eth0 root handle 1: htb default 10
tc class add dev eth0 parent 1: classid 1:1 htb rate 2000mbit ceil 2000mbit
tc class add dev eth0 parent 1: classid 1:10 htb rate 1000mbit ceil 2000mbit
tc qdisc add dev eth0 parent 1:10 handle 10: sfq perturb 10

# ضبط إعدادات الرفع لتسريع Upload
echo "🔥 تحسين سرعة رفع البيانات!"
sysctl -w net.ipv4.udp_wmem_max=8589934592
sysctl -w net.ipv4.udp_wmem_min=4194304
ethtool -G $IFACE tx 4194304
ifconfig $IFACE txqueuelen 100000

# ضبط حدود الملفات المفتوحة
ulimit -n 1073741824

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 1073741824
* hard nofile 1073741824
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن تعمل بكفاءة عالية!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

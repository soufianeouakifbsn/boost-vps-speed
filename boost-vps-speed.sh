#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة لتحقيق سرعة قصوى عبر UDP بإعدادات متقدمة! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 33554432
net.core.rfs_memory_limit = 134217728
net.core.netdev_max_backlog = 640000000

# تعزيز تدفق البيانات عبر UDP
net.core.optmem_max = 34359738368
net.ipv4.udp_mem = 16777216 134217728 274877906944
net.ipv4.udp_rmem_min = 16777216
net.ipv4.udp_wmem_min = 16777216
net.ipv4.udp_rmem_max = 8589934592
net.ipv4.udp_wmem_max = 17179869184

# تحسين إدارة حركة المرور عبر الشبكة
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=2
net.ipv4.tcp_ecn=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_nodelay=1
net.ipv4.tcp_tw_reuse=1
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق أقصى أداء!"
IFACE="eth0"
ethtool -G $IFACE rx 2097152 tx 2097152
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 50000 duplex full autoneg off  # ضبط السرعة إلى 50Gbps!
ethtool -K $IFACE xdp on  # تفعيل XDP لتحسين معالجة الحزم!

# ضبط MTU للحصول على تدفق ضخم للحزم
echo "📡 ضبط MTU إلى 9000!"
ifconfig $IFACE mtu 9000
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# ضبط أولوية الاتصال عبر QoS
echo "🔥 ضبط QoS لضمان تدفق سريع ومستقر!"
sysctl -w net.ipv4.fib_multipath_hash_policy=1

# تحسين استجابة الشبكة عبر Multi-Queue Processing
echo "⚡ تحسين معالجة الحزم لتقليل زمن الاستجابة!"
sysctl -w net.core.dev_weight=4096
sysctl -w net.core.netdev_budget=400000
sysctl -w net.core.netdev_budget_usecs=100000

# ضبط حدود الملفات المفتوحة
ulimit -n 2147483648

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 2147483648
* hard nofile 2147483648
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن في أقصى مستوى ممكن من السرعة والاستقرار!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

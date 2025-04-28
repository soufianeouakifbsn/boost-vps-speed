#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة لضمان سرعة قصوى عبر UDP! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 2097152
net.core.netdev_max_backlog = 80000000

# تعزيز تدفق البيانات عبر UDP
net.core.optmem_max = 4294967296
net.ipv4.udp_mem = 1048576 8388608 17179869184
net.ipv4.udp_rmem_min = 1048576
net.ipv4.udp_wmem_min = 1048576
net.ipv4.udp_rmem_max = 268435456
net.ipv4.udp_wmem_max = 268435456

# تحسين إدارة حركة المرور عبر الشبكة
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_ecn = 1
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق أقصى سرعة!"
IFACE="eth0"
ethtool -G $IFACE rx 262144 tx 262144
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 10000 duplex full autoneg off

# ضبط حدود الملفات المفتوحة
ulimit -n 268435456

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 268435456
* hard nofile 268435456
EOF

echo "✅ تم تطبيق جميع التعديلات! 🚀 الشبكة الآن جاهزة لنقل البيانات بسرعة خارقة عبر UDP!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

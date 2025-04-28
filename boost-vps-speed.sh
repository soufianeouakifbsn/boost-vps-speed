#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة لتحقيق سرعة قصوى عبر UDP! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 4194304
net.core.netdev_max_backlog = 160000000

# تعزيز تدفق البيانات عبر UDP
net.core.optmem_max = 8589934592
net.ipv4.udp_mem = 2097152 16777216 34359738368
net.ipv4.udp_rmem_min = 2097152
net.ipv4.udp_wmem_min = 2097152
net.ipv4.udp_rmem_max = 536870912
net.ipv4.udp_wmem_max = 536870912

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
ethtool -G $IFACE rx 524288 tx 524288
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 10000 duplex full autoneg off

# ضبط حدود الملفات المفتوحة
ulimit -n 536870912

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 536870912
* hard nofile 536870912
EOF

echo "✅ تم تطبيق جميع التعديلات! 🚀 الشبكة الآن جاهزة لنقل البيانات بسرعة خارقة عبر UDP!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

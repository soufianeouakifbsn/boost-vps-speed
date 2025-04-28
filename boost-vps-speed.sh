#!/bin/bash
echo "🔧 تحسين إعدادات الشبكة لنقل البيانات عبر UDP بسرعة خارقة! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 524288
net.core.netdev_max_backlog = 20000000

net.core.optmem_max = 1073741824
net.ipv4.udp_mem = 131072 4194304 8589934592
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.udp_rmem_max = 134217728
net.ipv4.udp_wmem_max = 134217728

net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_ecn = 1
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 تحسين إعدادات بطاقة الشبكة..."
IFACE="eth0"
ethtool -G $IFACE rx 65536 tx 65536
ethtool -C $IFACE rx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off

# ضبط حدود الملفات المفتوحة
ulimit -n 67108864

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 67108864
* hard nofile 67108864
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن جاهزة لنقل البيانات بأقصى سرعة ممكنة عبر UDP!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

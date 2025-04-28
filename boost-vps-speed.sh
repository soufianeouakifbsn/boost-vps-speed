#!/bin/bash
echo "🔧 تحسين إعدادات الشبكة لنقل البيانات عبر UDP بمستوى خارق! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
# تعزيز أداء نقل البيانات عبر UDP
net.core.rps_sock_flow_entries = 131072
net.core.netdev_max_backlog = 5000000

# زيادة حجم الـ UDP Buffer لمنع فقدان الحزم عند السرعات العالية
net.core.optmem_max = 268435456
net.ipv4.udp_mem = 32768 1048576 2147483647
net.ipv4.udp_rmem_min = 32768
net.ipv4.udp_wmem_min = 32768
net.ipv4.udp_rmem_max = 33554432
net.ipv4.udp_wmem_max = 33554432

# تحسين زمن التأخير (Latency) باستخدام fq + BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 2
EOF

# تطبيق الإعدادات
sysctl -p

# ضبط إعدادات بطاقة الشبكة باستخدام ethtool
echo "🔧 تحسين إعدادات بطاقة الشبكة..."
IFACE="eth0"
ethtool -G $IFACE rx 16384 tx 16384
ethtool -C $IFACE rx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off

# ضبط حدود الملفات المفتوحة
ulimit -n 16777216

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 16777216
* hard nofile 16777216
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن جاهزة لأقصى سرعة ممكنة عبر UDP!"

echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

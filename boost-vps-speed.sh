#!/bin/bash
echo "🔧 تحسين إعدادات الشبكة لنقل البيانات عبر UDP بسرعة قصوى! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
# تعزيز أداء نقل البيانات عبر UDP
net.core.rps_sock_flow_entries = 262144
net.core.netdev_max_backlog = 10000000

# زيادة حجم الـ UDP Buffer لمنع فقدان الحزم عند السرعات العالية
net.core.optmem_max = 536870912
net.ipv4.udp_mem = 65536 2097152 4294967295
net.ipv4.udp_rmem_min = 65536
net.ipv4.udp_wmem_min = 65536
net.ipv4.udp_rmem_max = 67108864
net.ipv4.udp_wmem_max = 67108864

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
ethtool -G $IFACE rx 32768 tx 32768
ethtool -C $IFACE rx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off

# ضبط حدود الملفات المفتوحة
ulimit -n 33554432

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 33554432
* hard nofile 33554432
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 الشبكة الآن جاهزة لنقل البيانات بسرعة فائقة عبر UDP!"

echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

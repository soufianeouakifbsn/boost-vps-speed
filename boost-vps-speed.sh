#!/bin/bash
echo "🔧 تحسين إعدادات الشبكة لنقل البيانات عبر UDP! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
# تعزيز أداء نقل البيانات عبر UDP
net.core.rps_sock_flow_entries = 65536
net.core.netdev_max_backlog = 3000000

# زيادة حجم الـ UDP Buffer لمنع فقدان الحزم عند السرعات العالية
net.core.optmem_max = 134217728
net.ipv4.udp_mem = 16384 524288 1073741824
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.udp_rmem_max = 16777216
net.ipv4.udp_wmem_max = 16777216

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
ethtool -G $IFACE rx 8192 tx 8192
ethtool -C $IFACE rx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off

# ضبط حدود الملفات المفتوحة
ulimit -n 8388608

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 8388608
* hard nofile 8388608
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 جاهز لنقل البيانات بسرعة فائقة عبر UDP!"

echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

#!/bin/bash
echo "🔧 تطبيق تحسينات خارقة على إعدادات الشبكة! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
# تفعيل RPS (Receive Packet Steering) و RFS (Receive Flow Steering)
net.core.rps_sock_flow_entries = 32768
net.core.netdev_max_backlog = 2000000

# زيادة حجم الـ UDP Buffer لمنع فقدان الحزم عند السرعات العالية
net.core.optmem_max = 67108864
net.ipv4.udp_mem = 8192 262144 536870912
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

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
ethtool -G $IFACE rx 4096 tx 4096
ethtool -C $IFACE rx-usecs 0

# ضبط حدود الملفات المفتوحة
ulimit -n 4194304

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 4194304
* hard nofile 4194304
EOF

echo "✅ تم تطبيق جميع التحسينات! 🚀 جاهز للطيران بسرعة البرق!"

echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

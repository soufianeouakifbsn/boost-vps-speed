#!/bin/bash
echo "🚀 تحسين الشبكة: مزيج من استقرار Cubic ودقة Vegas لتحقيق أفضل أداء! ⚡"

# تفعيل Cubic كخوارزمية رئيسية
echo "🔥 تفعيل CUBIC TCP لضمان تدفق بيانات سلس!"
cat > /etc/sysctl.conf <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = cubic

# تحسين استجابة الشبكة
net.ipv4.tcp_vegas_alpha = 1
net.ipv4.tcp_vegas_beta = 3
net.ipv4.tcp_vegas_gamma = 0
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1
net.ipv4.tcp_tw_reuse = 1

# تعزيز UDP Performance
net.core.rps_sock_flow_entries = 32768
net.core.netdev_max_backlog = 500000
net.core.optmem_max = 67108864
net.ipv4.udp_mem = 65536 131072 262144
net.ipv4.udp_rmem_min = 4096
net.ipv4.udp_wmem_min = 4096
net.ipv4.udp_rmem_max = 67108864
net.ipv4.udp_wmem_max = 67108864
EOF

sysctl -p

# ضبط إعدادات كرت الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحسين الأداء!"
IFACE="eth0"
ethtool -G $IFACE rx 8192 tx 8192
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off
ethtool -s $IFACE speed 10000 duplex full autoneg off
ethtool -K $IFACE xdp on

# تحسين MTU لو كان السيرفر يدعمها
echo "📡 ضبط MTU إلى 1500 (أو أعلى حسب الحاجة)!"
ifconfig $IFACE mtu 1500
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# تحسين الـ Buffer و QoS
echo "⚡ ضبط txqueuelen وتقسيم الحزم بسلاسة!"
ifconfig $IFACE txqueuelen 100000
tc qdisc replace dev $IFACE root fq_codel

# رفع حدود الملفات المفتوحة
ulimit -n 1048576
cat >> /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
EOF

echo "✅ تم تطبيق التحسينات بنجاح! 🚀 الشبكة الآن تجمع بين السرعة والاستقرار!"
echo "📢 يُنصح بإعادة تشغيل السيرفر لتفعيل الإعدادات كلياً."

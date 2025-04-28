#!/bin/bash

# 🚀 سكربت متطور يجمع بين مزايا TCP CUBIC وسرعة UDP لتحقيق أفضل استقرار وسرعة!

echo "🚀 بدء تحسين إعدادات الشبكة لتحقيق أقصى أداء واستقرار! ⚡"

# اختيار CUBIC كخوارزمية التحكم بالازدحام + تحسين خصائص TCP/UDP
cat > /etc/sysctl.conf <<EOF
# استخدام CUBIC لخوارزمية الازدحام الافتراضية
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = cubic

# تحسين UDP
net.core.rps_sock_flow_entries = 32768
net.core.netdev_max_backlog = 1000000
net.core.optmem_max = 65536
net.ipv4.udp_mem = 4096 87380 6291456
net.ipv4.udp_rmem_min = 4096
net.ipv4.udp_wmem_min = 4096
net.ipv4.udp_rmem_max = 134217728
net.ipv4.udp_wmem_max = 134217728

# تحسين TCP
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_nodelay = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_syncookies = 1
EOF

# تطبيق التعديلات
sysctl -p

# ضبط إعدادات كارت الشبكة
echo "🔧 ضبط إعدادات بطاقة الشبكة!"
IFACE="eth0"
ethtool -G $IFACE rx 4096 tx 4096
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off
ethtool -s $IFACE speed 50000 duplex full autoneg off
ethtool -K $IFACE xdp on

# تحسين الـ MTU
echo "📡 تعيين MTU إلى 9000!"
ifconfig $IFACE mtu 9000
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# تحسين الـ QoS باستخدام FQ + HTB
echo "🔥 تحسين تدفق البيانات باستخدام FQ و HTB!"
tc qdisc replace dev $IFACE root handle 1: htb default 10
tc class add dev $IFACE parent 1: classid 1:1 htb rate 5000mbit ceil 5000mbit
tc class add dev $IFACE parent 1: classid 1:10 htb rate 2500mbit ceil 5000mbit
tc qdisc add dev $IFACE parent 1:10 handle 10: fq

# ضبط txqueuelen لمزيد من الثبات
echo "⚡ تعيين txqueuelen لمنع الاختناق!"
ifconfig $IFACE txqueuelen 200000

# ضبط حدود الملفات المفتوحة
echo "📈 رفع حدود الملفات المفتوحة!"
ulimit -n 1048576
cat >> /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
EOF

echo "✅ تم تطبيق كل التحسينات! 🚀 الشبكة الآن جاهزة للأداء العالي! "
echo "📢 ملاحظة: يُفضل إعادة تشغيل السيرفر لضمان تحميل كل الإعدادات بشكل كامل."

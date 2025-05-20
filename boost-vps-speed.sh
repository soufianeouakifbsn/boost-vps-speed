#!/bin/bash
set -e
echo "🚨 تعديل الإعدادات لحل مشكلة التقطعات عبر UDP tethering"

# تحديد واجهة الشبكة
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 اكتشاف الواجهة: $IFACE"

# إعادة sysctl مع تخفيف الضغط
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 2097152
net.core.wmem_default = 2097152
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_mem = 65536 131072 262144
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_fastopen = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_adv_win_scale = 1
vm.swappiness = 10
EOF

sysctl -p

# إعادة MTU إلى القيمة الطبيعية
ip link set dev $IFACE mtu 1500

# حذف كل إعدادات tc و iptables التي قد تؤثر على الأداء
tc qdisc del dev $IFACE root 2>/dev/null || true

iptables -t mangle -F
iptables -t raw -F

# إعادة governor إلى powersave لتقليل الحرارة والطاقة
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo powersave > $cpu 2>/dev/null || true
done

# تعطيل irqbalance مؤقتًا
systemctl stop irqbalance
systemctl disable irqbalance

echo "✅ تم التعديل لتقليل التقطعات"
echo "🧪 جرب الآن الاتصال لمدة 5-10 دقائق وراقب هل المشكلة اختفت"

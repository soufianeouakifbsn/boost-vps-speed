#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات لتقليل التقطّع عبر UDP tethering على Ubuntu 20.04"

# اكتشاف واجهة الشبكة تلقائيًا
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# تحديث إعدادات sysctl
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_mem = 65536 131072 262144
net.core.netdev_max_backlog = 2500
net.core.somaxconn = 1024
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_adv_win_scale = 1
vm.swappiness = 10
EOF

sysctl -p

# رفع حد الملفات المفتوحة
cat > /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF

ulimit -n 65536

# حذف أي إعدادات qdisc مسبقة وتطبيق fq_codel
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root fq_codel

# تعيين MTU متوسط لتفادي التجزئة والتقطّع
ip link set dev $IFACE mtu 1400

# تعطيل تتبع الاتصال للبروتوكول UDP لتقليل الحمل
iptables -t raw -D PREROUTING -p udp -j NOTRACK 2>/dev/null || true
iptables -t raw -D OUTPUT -p udp -j NOTRACK 2>/dev/null || true
iptables -t raw -A PREROUTING -p udp -j NOTRACK
iptables -t raw -A OUTPUT -p udp -j NOTRACK

# تعطيل الجدار الناري مؤقتًا (اختياري فقط إذا تأكدت من الأمان)
ufw disable || true

# تحميل وحدة BBR
modprobe tcp_bbr
echo "tcp_bbr" | tee -a /etc/modules-load.d/modules.conf

# تفعيل performance mode لوحدة المعالجة المركزية
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > $cpu 2>/dev/null || true
done

# تفعيل irqbalance
systemctl enable irqbalance
systemctl start irqbalance

echo "✅ تم تطبيق التحسينات بنجاح 🎯"
echo "🔁 يُنصح بإعادة تشغيل الجهاز لتفعيل كل شيء: sudo reboot"

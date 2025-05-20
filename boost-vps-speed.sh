#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متخصصة لتخفيض ping عبر tethering UDP"

# اكتشاف واجهة الشبكة
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# إعدادات sysctl
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 2097152
net.core.wmem_default = 2097152
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.udp_mem = 131072 262144 524288
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 131072 262144 524288
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_low_latency = 1
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 1024
net.ipv4.ip_forward = 1
vm.swappiness = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 0
EOF

sysctl -p

# رفع حد الملفات المفتوحة
cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

ulimit -n 1048576

# تطبيق إعدادات qdisc
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root fq_codel

# خفض الـ MTU قليلاً لأنه مفيد في حالات الـ UDP over tunnel
ip link set dev $IFACE mtu 1350

# تحسين iptables للـ UDP
iptables -t mangle -N UDP_MARK 2>/dev/null || true
iptables -t mangle -F UDP_MARK
iptables -t mangle -A UDP_MARK -j MARK --set-mark 1
iptables -t mangle -A UDP_MARK -j DSCP --set-dscp-class EF
iptables -t mangle -A OUTPUT -p udp -j UDP_MARK
iptables -t mangle -A PREROUTING -p udp -j UDP_MARK

# تعطيل تتبع الاتصال لـ UDP (مفيد في بعض حالات الـ TUN)
iptables -t raw -A PREROUTING -p udp -j NOTRACK
iptables -t raw -A OUTPUT -p udp -j NOTRACK

# تفعيل BBR
modprobe tcp_bbr
echo "tcp_bbr" | tee -a /etc/modules-load.d/modules.conf

# تحسين ترددات المعالج
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > $cpu 2>/dev/null || true
done

# تفعيل irqbalance
systemctl enable irqbalance
systemctl start irqbalance

echo "✅ تم تطبيق التحسينات بنجاح 🎯"
echo "🔁 يُفضل إعادة التشغيل لتفعيل جميع الإعدادات: sudo reboot"

#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات محسّنة لتقليل ping وتحسين استقرار UDP Custom"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام ========
cat > /etc/sysctl.conf <<EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.core.netdev_max_backlog = 50000
net.core.somaxconn = 4096
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_forward = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

sysctl -p

# ======== حدود الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 262144
* hard nofile 262144
root soft nofile 262144
root hard nofile 262144
EOF

ulimit -n 262144

# ======== إزالة إعدادات traffic control القديمة ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# ======== استخدام جدولة FQ البسيطة بدون HTB ========
tc qdisc add dev $IFACE root fq maxrate 100mbit

# ======== تعيين حجم الطابور والإرسال ========
ip link set dev $IFACE txqueuelen 4000
ip link set dev $IFACE mtu 1400

# ======== iptables – إلغاء إعدادات mark المعقدة التي قد تسبب بطء ========
iptables -t mangle -F
ip6tables -t mangle -F

# ======== تحسينات موارد النظام ========
echo 65536 > /proc/sys/kernel/threads-max
echo 65536 > /proc/sys/vm/max_map_count
echo 65536 > /proc/sys/kernel/pid_max

# ======== خدمة systemd خفيفة للتحسينات عند الإقلاع ========
cat > /etc/systemd/system/udp-custom-optimize.service <<EOF
[Unit]
Description=UDP Custom Optimization (Low Latency)
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
IFACE=\$(ip -o -4 route show to default | awk "{print \$5}");
tc qdisc del dev \$IFACE root 2>/dev/null || true;
tc qdisc add dev \$IFACE root fq maxrate 100mbit;
ip link set dev \$IFACE txqueuelen 4000;
ip link set dev \$IFACE mtu 1400;
iptables -t mangle -F;
ip6tables -t mangle -F;
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom-optimize.service

echo "✅ تم تطبيق التحسينات الجديدة بنجاح!"
echo "🔁 يُنصح بإعادة التشغيل الآن لتفعيل كل التعديلات: sudo reboot"

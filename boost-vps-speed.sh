#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متقدمة لزيادة استقرار اتصال UDP Custom مع HTTP Custom App"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام ========
cat > /etc/sysctl.conf <<EOF
# تحسينات أساسية لـ UDP
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.udp_rmem_min = 65536
net.ipv4.udp_wmem_min = 65536
net.ipv4.udp_mem = 66560 89152 134217728

# تحسينات عامة للأداء
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 65535
net.core.optmem_max = 25165824
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 2

# تحسينات إدارة الذاكرة
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# تحسينات التوجيه
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535

# تعطيل بعض الميزات غير الضرورية
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
EOF

sysctl -p

# ======== إعداد حدود الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

ulimit -n 1048576

# ======== تنظيف إعدادات QoS السابقة ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# ======== إعداد QoS باستخدام Cake للتحكم الذكي في الازدحام ========
tc qdisc add dev $IFACE root cake bandwidth 1gbit besteffort \
    dual-dsthost diffserv3 \
    nat nowash no-ack-filter split-gso rtt 100ms

# ======== تحسين إعدادات الواجهة ========
ip link set dev $IFACE txqueuelen 10000
ip link set dev $IFACE mtu 1492  # تعديل وفقًا لـ MTU الأمثل لشبكتك

# ======== إعدادات متقدمة لـ IRQ Balancing ========
if [[ -f /etc/default/irqbalance ]]; then
    sed -i 's/ENABLED="0"/ENABLED="1"/' /etc/default/irqbalance
    systemctl restart irqbalance
fi

# ======== تحسين إعدادات iptables لـ UDP ========
iptables -t mangle -F
ip6tables -t mangle -F

iptables -t mangle -N UDP_PRIORITY 2>/dev/null || true
iptables -t mangle -F UDP_PRIORITY

iptables -t mangle -A UDP_PRIORITY -p udp -m length --length 0:1280 -j MARK --set-mark 0x1
iptables -t mangle -A UDP_PRIORITY -p udp -m length --length 1281: -j MARK --set-mark 0x2

iptables -t mangle -A POSTROUTING -o $IFACE -p udp -j UDP_PRIORITY

# ======== إنشاء خدمة systemd ديناميكية ========
cat > /etc/systemd/system/udp-optimizer.service <<EOF
[Unit]
Description=Dynamic UDP Connection Optimizer
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sysctl -p; \
tc qdisc replace dev $IFACE root cake bandwidth 1gbit besteffort dual-dsthost diffserv3 nat nowash no-ack-filter split-gso rtt 100ms; \
ip link set dev $IFACE txqueuelen 10000; \
ip link set dev $IFACE mtu 1492; \
iptables -t mangle -A POSTROUTING -o $IFACE -p udp -j UDP_PRIORITY;'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-optimizer.service

echo "✅ تم التطبيق بنجاح مع التركيز على استقرار الاتصال!"
echo "➡️ المزايا الجديدة:"
echo "- استخدام خوارزمية Cake الذكية لإدارة الازدحام"
echo "- تحسين توزيع حزم UDP حسب الحجم"
echo "- ضبط MTU ديناميكي"
echo "- تحسين توازن IRQ"
echo "⚠️ يُنصح بإعادة التشغيل: sudo reboot"

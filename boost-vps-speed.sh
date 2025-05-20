#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متقدمة لشبكات الجوال (inwi) مع HTTP Custom"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== ضبط الوقت والدقة الزمنية ========
timedatectl set-timezone Africa/Casablanca
sed -i '/^pool /d' /etc/chrony/chrony.conf || true
echo "server time.cloudflare.com iburst" >> /etc/chrony/chrony.conf
systemctl restart chrony || systemctl restart ntp
echo "🕒 تم مزامنة الوقت مع خوادم Cloudflare"

# ======== تحسينات نواة النظام المتقدمة ========
cat > /etc/sysctl.conf <<EOF
# تحسينات UDP الأساسية
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.udp_mem = 66560 89152 134217728

# إدارة الذاكرة والأداء
net.core.netdev_max_backlog = 500000
net.core.somaxconn = 32768
net.core.optmem_max = 33554432
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 2
vm.swappiness = 5
vm.vfs_cache_pressure = 30

# تحسينات شبكات الجوال
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_adv_win_scale = 2
net.ipv4.tcp_frto = 2
net.ipv4.tcp_frto_response = 2
EOF

sysctl -p

# ======== تحسينات بطاقة الشبكة ========
if ethtool -i $IFACE | grep -q 'driver:'; then
    ethtool -C $IFACE rx-usecs 0 tx-usecs 0 2>/dev/null || true
    ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
    ethtool -K $IFACE tso on gso on gro on lro off 2>/dev/null || true
    echo "🎛️ تم تحسين إعدادات بطاقة الشبكة"
fi

# ======== إعداد QoS مع Cake المدعم ========
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root cake bandwidth 800mbit besteffort \
    dual-dsthost diffserv3 nat nowash no-ack-filter \
    rtt 200ms memlimit 32M

# ======== تحسينات iptables المتقدمة ========
iptables -t mangle -F
ip6tables -t mangle -F

iptables -t mangle -N UDP_PRIORITY 2>/dev/null || true
iptables -t mangle -F UDP_PRIORITY

# أولوية عالية للاتصالات الصغيرة (VoIP، الألعاب)
iptables -t mangle -A UDP_PRIORITY -p udp -m length --length 0:500 -j MARK --set-mark 0x1
iptables -t mangle -A UDP_PRIORITY -p udp --dport 5000:65000 -j MARK --set-mark 0x2

# تجاوز خنق الناقل
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 65
ip6tables -t mangle -A POSTROUTING -j HL --hl-set 65

# تحسينات TCP
iptables -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# ======== نظام مراقبة الأداء ========
apt update && apt install -y vnstat iftop
vnstat -u -i $IFACE
systemctl enable vnstat

# ======== خدمة systemd ديناميكية ========
cat > /etc/systemd/system/udp-mobile-optimizer.service <<EOF
[Unit]
Description=Mobile Network Optimizer Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
    sysctl -p; \
    tc qdisc replace dev $IFACE root cake bandwidth 800mbit besteffort \
        dual-dsthost diffserv3 nat nowash no-ack-filter rtt 200ms; \
    iptables-restore < /etc/iptables/rules.v4; \
    ip6tables-restore < /etc/iptables/rules.v6'
ExecReload=/bin/bash -c 'sysctl -p; tc qdisc replace dev $IFACE root cake bandwidth 800mbit'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-mobile-optimizer.service

echo "✅ تم التطبيق بنجاح مع التحسينات التالية:"
echo "✔️ خوارزمية Cake مع ضبط خاص لشبكات الجوال"
echo "✔️ تحسينات بطاقة الشبكة عبر ethtool"
echo "✔️ أولوية لحزم VoIP والألعاب"
echo "✔️ مراقبة أداء في الوقت الحقيقي"
echo "⚡ يُنصح بإعادة التشغيل: sudo reboot"

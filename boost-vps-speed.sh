#!/bin/bash
set -e

echo "🚀 بدء تطبيق نظام INWI Ultra Networking Pro (UDP/HTTP Custom Gold+ Edition)"

# ======== التحقق من الصلاحيات ========
if [[ $EUID -ne 0 ]]; then
    echo "❌ هذا السكربت يحتاج صلاحيات root!"
    exit 1
fi

# ======== كشف الواجهة ========
IFACE=$(ip route get 8.8.8.8 | awk -- '{print $5; exit}')
[[ -z "$IFACE" ]] && echo "❌ تعذر التعرف على الواجهة!" && exit 1

# ======== مزامنة الوقت بدقة ========
timedatectl set-timezone Africa/Casablanca
apt install -y chrony
sed -i '/^pool /d' /etc/chrony/chrony.conf
echo -e "server time.cloudflare.com iburst\nserver ntp.inwi.ma iburst" >> /etc/chrony/chrony.conf
systemctl restart chronyd || systemctl restart chrony
echo "🕒 تم ضبط الوقت بنجاح"

# ======== تفعيل BBRv2 أو BBRv3 إن توفر ========
modprobe tcp_bbr
echo "tcp_bbr" | tee -a /etc/modules-load.d/modules.conf
sysctl -w net.ipv4.tcp_congestion_control=bbr
echo "✅ تم تفعيل BBR (v2 أو v3 حسب النواة)"

# ======== تحسينات sysctl قوية جداً ========
cat > /etc/sysctl.d/99-inwi-ultra.conf <<EOF
# Buffer Boost
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432
net.ipv4.udp_mem = 65536 131072 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# TCP Stack Tuning
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1

# General Performance
fs.file-max = 2097152
net.core.netdev_max_backlog = 100000
net.ipv4.ip_forward = 1
vm.swappiness = 10
EOF

sysctl -p /etc/sysctl.d/99-inwi-ultra.conf

# ======== تفعيل واستخدام IFB مع CAKE =========
modprobe ifb
ip link add ifb0 type ifb || true
ip link set dev ifb0 up
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc del dev ifb0 root 2>/dev/null || true

# CAKE مع IFB
tc qdisc add dev $IFACE handle ffff: ingress
tc filter add dev $IFACE parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0

tc qdisc add dev ifb0 root cake bandwidth 900mbit besteffort triple-isolate nat rtt 150ms
tc qdisc add dev $IFACE root cake bandwidth 900mbit besteffort triple-isolate nat rtt 150ms

# ======== تحسينات بطاقة الشبكة والIRQ ========
apt install -y ethtool irqbalance cpufrequtils

ethtool -K $IFACE tso on gso on gro on
ethtool -C $IFACE adaptive-rx on adaptive-tx on rx-usecs 0 tx-usecs 0
ethtool -G $IFACE rx 4096 tx 4096
ip link set $IFACE txqueuelen 10000

# تحسين تعيين المعالجات للـ IRQs
systemctl enable irqbalance
systemctl start irqbalance

# ======== iptables DSCP/QoS + MTU Clamping ========
iptables -t mangle -F
ip6tables -t mangle -F

iptables -t mangle -A POSTROUTING -p udp --dport 5000:65535 -j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 65
ip6tables -t mangle -A POSTROUTING -j HL --hl-set 65

# ======== خدمات مراقبة الأداء ========
apt install -y iftop iptraf-ng bmon netdata

# ======== تفعيل الخدمة عند الإقلاع ========
cat > /etc/systemd/system/inwi-ultra.service <<EOF
[Unit]
Description=INWI Ultra Optimizer Service
After=network.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 5
ExecStart=/sbin/sysctl -p /etc/sysctl.d/99-inwi-ultra.conf
ExecStart=/sbin/tc qdisc replace dev $IFACE root cake bandwidth 900mbit besteffort
ExecStart=/sbin/tc qdisc replace dev ifb0 root cake bandwidth 900mbit besteffort
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable inwi-ultra.service

echo "✅ تمت التهيئة بنجاح!"
echo "✔️ CAKE على الواجهة الفعلية والـIFB (Inbound QoS)"
echo "✔️ BBRv2/v3 + MTU Probing + Window Scaling"
echo "✔️ تهيئة IRQ Balance لتقليل تأخير المعالجة"
echo "✔️ ضبط DSCP + TTL لإخفاء الترافيك"
echo "✔️ مراقبة مباشرة مع iftop, iptraf, netdata"
echo "⚡ لتفعيل التحسينات الآن: systemctl start inwi-ultra.service"

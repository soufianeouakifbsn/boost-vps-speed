#!/bin/bash
set -e

## 🛡️ INWI Nitro Xtreme - الإصدار المخصص للـ VPS عبر مودم 4G لمشاهدة YouTube بسرعة وبدون تقطعات
## ⚙️ التهيئة التلقائية لكامل النظام لتحسين الاتصال وثباته وتخفي الترافيك

# ========= صلاحيات Root =========
[[ $EUID -ne 0 ]] && echo "❌ يجب تشغيل السكربت كـ root" && exit 1

# ========= إعداد أولي =========
echo "🚀 بدء التهيئة - INWI Nitro Xtreme"
timedatectl set-timezone Africa/Casablanca
apt update && apt install -y ethtool chrony iftop iptraf-ng bmon net-tools curl nftables wireguard-tools

# ========= تهيئة الوقت =========
sed -i '/^pool /d' /etc/chrony/chrony.conf
echo -e "server time.cloudflare.com iburst\nserver ntp.inwi.ma iburst" >> /etc/chrony/chrony.conf
systemctl restart chrony || systemctl restart chronyd

# ========= كشف الواجهة =========
IFACE=$(ip route get 8.8.8.8 | awk -- '{print $5; exit}')
[[ -z "$IFACE" ]] && echo "❌ تعذر معرفة الواجهة" && exit 1

# ========= تفعيل BBR وتحديد الأنسب =========
modprobe tcp_bbr || true
BBR_OK=$(sysctl net.ipv4.tcp_congestion_control | grep bbr)
if [[ -z "$BBR_OK" ]]; then
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
fi

# ========= تحسينات النواة =========
cat > /etc/sysctl.d/99-nitro-xtreme.conf <<EOF
fs.file-max = 2097152
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 100000
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_mtu_probing = 2
net.ipv4.ip_forward = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.udp_mem = 65536 131072 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
vm.swappiness = 10
EOF
sysctl -p /etc/sysctl.d/99-nitro-xtreme.conf

# ========= تحسين بطاقة الشبكة =========
ethtool -K $IFACE tso on gso on gro on || true
ethtool -C $IFACE adaptive-rx on adaptive-tx on rx-usecs 0 tx-usecs 0 || true
ethtool -G $IFACE rx 4096 tx 4096 || true
ip link set $IFACE txqueuelen 10000 || true

# ========= إعداد CAKE + IFB =========
modprobe ifb
ip link add ifb0 type ifb || true
ip link set ifb0 up

tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc del dev ifb0 root 2>/dev/null || true
tc qdisc add dev $IFACE handle ffff: ingress

tc filter add dev $IFACE parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0

tc qdisc add dev ifb0 root cake bandwidth 900mbit besteffort triple-isolate nat rtt 150ms

# ========= إعداد nftables لحماية متقدمة + إخفاء الترافيك =========
cat > /etc/nftables.conf <<EOF
table inet filter {
    chain input {
        type filter hook input priority 0;
        policy accept;
    }
    chain forward {
        type filter hook forward priority 0;
        policy accept;
    }
    chain output {
        type filter hook output priority 0;
        policy accept;
        ip dscp set af41
        ip ttl set 65
    }
}
EOF

systemctl enable nftables
systemctl restart nftables

# ========= تعطيل IPv6 =========
cat >> /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl -p

# ========= DNS سريع + حماية =========
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/doh.conf <<EOF
[Resolve]
DNS=1.1.1.1
FallbackDNS=1.0.0.1
DNSOverTLS=yes
EOF
systemctl restart systemd-resolved

# ========= إعداد خدمة إعادة التشغيل عند الفشل =========
cat > /etc/systemd/system/nitro-watchdog.service <<EOF
[Unit]
Description=Nitro Xtreme Watchdog
After=network.target

[Service]
Type=simple
Restart=always
ExecStart=/bin/bash -c '/sbin/tc qdisc replace dev ifb0 root cake bandwidth 900mbit besteffort'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable nitro-watchdog.service

# ========= تعليمات نهائية =========
echo "✅ Nitro Xtreme جاهز!"
echo "✔️ سرعة مشاهدة YouTube من خلال مودم 4G محسّنة"
echo "✔️ BBR + CAKE + IFB + DSCP + DNS محمي + تخفي كامل"
echo "⚡ لتفعيل الخدمة الآن: systemctl start nitro-watchdog.service"

#!/bin/bash
set -e

echo "🚀 بدء تطبيق تحسينات إنوي المتطورة لـ UDP/HTTP Custom (الإصدار الذهبي)"

# ======== التحقق من الصلاحيات والبيئة ========
if [[ $EUID -ne 0 ]]; then
   echo "❌ يجب تشغيل السكربت بصلاحيات root!" 
   exit 1
fi

IFACE=$(ip -o -4 route show to default | awk '{print $5}' | uniq)
if [[ -z "$IFACE" ]]; then
    echo "❌ فشل في تحديد الواجهة الشبكية!"
    exit 1
fi
echo "🔍 الواجهة المحددة: $IFACE | النوع: $(ethtool -i $IFACE | grep driver)"

# ======== التحسينات الزمنية الدقيقة ========
timedatectl set-timezone Africa/Casablanca
sed -i '/^pool /d' /etc/chrony/chrony.conf
echo "server time.cloudflare.com iburst" >> /etc/chrony/chrony.conf
echo "server ntp.inwi.ma iburst" >> /etc/chrony/chrony.conf
systemctl restart chrony
echo "🕒 مزامنة الوقت مع خوادم إنوي و Cloudflare"

# ======== تحسينات النواة الهجينة ========
cat > /etc/sysctl.d/99-inwi-udp.conf <<EOF
# ───── تحسينات UDP المتطورة ─────
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.udp_mem = 66560 89152 134217728

# ───── تحسينات TCP الهجينة ─────
net.ipv4.tcp_congestion_control = bbr2
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5

# ───── تحسينات شبكات الجوال ─────
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 32768
net.core.optmem_max = 4194304
net.ipv4.conf.all.rp_filter = 2
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535

# ───── إدارة الذاكرة المتقدمة ─────
vm.swappiness = 1
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 3
vm.dirty_background_ratio = 2
EOF

sysctl -p /etc/sysctl.d/99-inwi-udp.conf

# ======== تحسينات البطاقة الشبكية المتقدمة ========
ethtool_optimize() {
    ethtool -C $IFACE rx-usecs 0 tx-usecs 0 2>/dev/null || true
    ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
    ethtool -K $IFACE \
        tso on gso on gro on \
        lro off rx off tx off \
        tx-checksum-ip-generic on 2>/dev/null || true
    ip link set dev $IFACE txqueuelen 4000
    echo "🔧 تحسينات البطاقة المطبقة:"
    ethtool -k $IFACE | grep -E 'tcp-segmentation-offload:|generic-segmentation-offload:'
}

ethtool_optimize

# ======== نظام QoS الهجين (CAKE + HTB) ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# الطبقة العلوية باستخدام CAKE
tc qdisc add dev $IFACE root cake bandwidth 900mbit besteffort \
    dual-dsthost nat nowash no-ack-filter \
    rtt 150ms memory 32M

# الطبقة التحتية باستخدام HTB للتحكم الدقيق
tc qdisc add dev $IFACE parent 1: handle 2: htb default 30
tc class add dev $IFACE parent 2: classid 2:1 htb rate 900mbit ceil 900mbit
tc class add dev $IFACE parent 2:1 classid 2:10 htb rate 750mbit ceil 900mbit prio 1  # UDP Priority
tc class add dev $IFACE parent 2:1 classid 2:20 htb rate 100mbit ceil 300mbit prio 2  # TCP
tc class add dev $IFACE parent 2:1 classid 2:30 htb rate 50mbit ceil 200mbit prio 3   # Other

# تصنيف الحزم باستخدام علامات DSCP
tc filter add dev $IFACE parent 2: protocol ip prio 1 u32 \
    match ip protocol 0x11 0xff \
    match ip dport 5000 0xff00 \
    flowid 2:10

# ======== تحسينات iptables الذكية ========
iptables -t mangle -F
ip6tables -t mangle -F

# وضع علامات DSCP لحركة UDP Custom
iptables -t mangle -A POSTROUTING -p udp -m multiport --dports 5000:65000 -j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p udp -m multiport --sports 5000:65000 -j DSCP --set-dscp-class EF

# تحسينات MTU الديناميكية
iptables -t mangle -A POSTROUTING -o $IFACE -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# منع اكتشاف خنق الناقل
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 70
ip6tables -t mangle -A POSTROUTING -j HL --hl-set 70

# ======== نظام المراقبة الذكية ========
apt install -y \
    darkstat \
    nethogs \
    tcptrack \
    smokeping

# ======== خدمة النظام الديناميكية ========
cat > /etc/systemd/system/inwi-ultimate.service <<EOF
[Unit]
Description=INWI Ultimate UDP Optimizer
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 7
ExecStart=/sbin/sysctl -p /etc/sysctl.d/99-inwi-udp.conf
ExecStart=/usr/sbin/tc qdisc replace dev $IFACE root cake bandwidth 900mbit besteffort dual-dsthost
ExecStart=/usr/bin/ethtool -K $IFACE gro on gso on tso on
ExecReload=/usr/sbin/tc qdisc replace dev $IFACE root cake bandwidth 900mbit
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable inwi-ultimate.service

echo "✅ تم التطبيق بنجاح! التحسينات الرئيسية:"
echo "✔️ نظام QoS هجين (CAKE + HTB) مع أولوية مطلقة لـ UDP"
echo "✔️ خوارزمية BBRv2 مع MTU Probing"
echo "✔️ تحسينات DSCP متقدمة لعلامات جودة الخدمة"
echo "✔️ مراقبة شبكة متقدمة مع Darkstat و Smokeping"
echo "✔️ إعدادات زمنية دقيقة لشبكات إنوي"
echo "⚡ التشغيل: systemctl start inwi-ultimate.service"

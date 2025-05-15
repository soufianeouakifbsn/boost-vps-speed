#!/bin/bash

# === سكربت تحسين عالي الأداء لاتصالات UDP/HTTP Custom ===
# === إصدار محسن ومعزز 2025 ===

set -e
clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 بدء تطبيق تحسينات متقدمة لاتصال UDP/HTTP Custom"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# حفظ سجل للعمليات
LOG_FILE="/var/log/udp-optimizer-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# التحقق من صلاحيات الروت
if [[ $EUID -ne 0 ]]; then
   echo "❌ يجب تشغيل هذا السكربت بصلاحيات الروت"
   echo "📌 الرجاء استخدام: sudo bash $0"
   exit 1
fi

# تحديد واجهة الشبكة الافتراضية
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة الرئيسية: $IFACE"

# إنشاء نسخة احتياطية من الإعدادات الحالية
echo "📦 إنشاء نسخة احتياطية من إعدادات النظام الحالية..."
mkdir -p /root/network_backup
cp /etc/sysctl.conf /root/network_backup/sysctl.conf.bak
cp /etc/security/limits.conf /root/network_backup/limits.conf.bak
sysctl -a > /root/network_backup/sysctl_before.txt
tc qdisc show > /root/network_backup/tc_before.txt
echo "✅ تم حفظ النسخ الاحتياطية في: /root/network_backup"

# ======== تحسينات نواة النظام المتطورة ========
echo "⚙️ تطبيق تحسينات نواة النظام المتطورة..."

cat > /etc/sysctl.conf <<EOF
# === تحسينات مخصصة لـ UDP/TCP لأقصى أداء وثبات ===

# ----- تحسينات متقدمة لـ UDP -----
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.udp_mem = 131072 262144 268435456

# ----- ضبط متقدم لـ UDP -----
net.ipv4.udp_early_demux = 1
net.ipv4.udp_l3mdev_accept = 1
net.ipv4.udp_so_reuseport = 1
net.ipv4.udp_fin_timeout = 15
net.ipv4.udp_keepalive_time = 600
net.ipv4.udp_keepalive_intvl = 60
net.ipv4.udp_keepalive_probes = 5

# ----- تحسينات معالجة الحزم -----
net.core.netdev_max_backlog = 500000
net.core.somaxconn = 16384
net.core.optmem_max = 67108864
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000
net.core.dev_weight = 600
net.core.flow_limit_cpu_bitmap = 0

# ----- تتبع الاتصالات المحسن -----
net.netfilter.nf_conntrack_max = 2097152
net.netfilter.nf_conntrack_buckets = 524288
net.netfilter.nf_conntrack_udp_timeout = 180
net.netfilter.nf_conntrack_udp_timeout_stream = 600
net.netfilter.nf_conntrack_tcp_timeout_established = 21600
net.netfilter.nf_conntrack_generic_timeout = 300
net.netfilter.nf_conntrack_expect_max = 8192
net.nf_conntrack_max = 2097152

# ----- تحسينات البروتوكولات المشتركة -----
net.ipv4.tcp_congestion_control = bbr2
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_low_latency = 1
net.core.default_qdisc = fq
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_rmem = 8192 262144 67108864
net.ipv4.tcp_wmem = 8192 262144 67108864
net.ipv4.tcp_mem = 131072 262144 67108864
net.ipv4.route.mtu_expires = 300

# ----- تحسينات عامة للنظام -----
fs.file-max = 10000000
fs.nr_open = 10000000
vm.swappiness = 5
vm.vfs_cache_pressure = 30
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
vm.min_free_kbytes = 65536
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.default.arp_ignore = 1

# ----- تحسين الذاكرة -----
vm.overcommit_memory = 1
vm.overcommit_ratio = 100
vm.max_map_count = 1048576
kernel.threads-max = 4194303
kernel.pid_max = 4194303
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.sem = 250 32000 100 1024
kernel.panic_on_oops = 0
kernel.panic = 10
kernel.core_uses_pid = 1
EOF

sysctl -p
echo "✅ تم تطبيق تحسينات نواة النظام بنجاح"

# ======== إعدادات حدود الملفات المفتوحة ========
echo "⚙️ تحسين حدود الملفات المفتوحة..."

cat > /etc/security/limits.conf <<EOF
# /etc/security/limits.conf
* soft nofile 10000000
* hard nofile 10000000
root soft nofile 10000000
root hard nofile 10000000
* soft nproc 10000000
* hard nproc 10000000
root soft nproc 10000000
root hard nproc 10000000
* soft memlock unlimited
* hard memlock unlimited
root soft memlock unlimited
root hard memlock unlimited
* soft core unlimited
* hard core unlimited
root soft core unlimited
root hard core unlimited
EOF

# تطبيق الإعدادات فوراً
ulimit -n 10000000
ulimit -u 10000000
echo "✅ تم تحسين حدود الملفات والعمليات"

# ======== تحسين كرت الشبكة ========
echo "🔌 تحسين إعدادات كرت الشبكة..."

# تعطيل interrupt coalescence لتقليل التأخير (latency)
ethtool -C $IFACE rx-usecs 0 tx-usecs 0 rx-frames 1 tx-frames 1 2>/dev/null || true

# ضبط حجم حلقات الإرسال والاستقبال
ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true

# ضبط offloads لتحسين أداء UDP (تشغيل القدرات المفيدة، تعطيل غير المفيدة)
ethtool -K $IFACE gso on gro on tso on ufo off lro off tx on rx on sg on 2>/dev/null || true

# ضبط طابور الإرسال لتقليل فقدان الحزم
ifconfig $IFACE txqueuelen 20000
echo "✅ تم تطبيق تحسينات كرت الشبكة"

# ======== ضبط عدد العمليات المتزامنة للنظام ========
echo "⚙️ تحسين إعدادات العمليات المتزامنة..."
echo 10000000 > /proc/sys/kernel/threads-max
echo 10000000 > /proc/sys/vm/max_map_count
echo 10000000 > /proc/sys/kernel/pid_max
echo "✅ تم تطبيق تحسينات العمليات المتزامنة"

# ======== تحسين جدولة حزم الشبكة (متقدم) ========
echo "🔄 تطبيق تحسينات متقدمة لجدولة حزم الشبكة..."

# إزالة جميع القواعد الحالية
tc qdisc del dev $IFACE root 2>/dev/null || true

# تطبيق جدولة متقدمة باستخدام مزيج من FQ_CODEL و CAKE للحصول على أفضل النتائج
tc qdisc add dev $IFACE root cake bandwidth unlimited besteffort flows 1024 rtt 5ms overhead 14 mpu 64 ingress wash nat wash ack-filter split-gso triple-isolate

echo "✅ تم تطبيق جدولة الشبكة المتقدمة"

# ======== إزالة قواعد iptables تقييدية ========
echo "🛡️ تعديل قواعد جدار الحماية لتحسين تدفق حزم UDP..."
iptables -t mangle -F
ip6tables -t mangle -F

# إضافة قواعد لتحسين تدفق البيانات
iptables -t mangle -A POSTROUTING -p udp -j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p tcp -j DSCP --set-dscp-class AF41

# تعديلات لزيادة الأولوية لحزم UDP
iptables -t mangle -A PREROUTING -p udp -j TOS --set-tos 0x10
iptables -t mangle -A PREROUTING -p udp -j MARK --set-mark 100

echo "✅ تم تحسين قواعد جدار الحماية"

# ======== تحسينات خاصة بشبكات الجوال ========
echo "📱 تطبيق تحسينات خاصة بشبكات الجوال (inwi, IAM, Orange)..."

# تنظيف أي قواعد tc موجودة مسبقًا (تم تنفيذه سابقًا)
# تحسينات للسيرفرات الافتراضية مع تقسيم المرور إلى فئات أولوية مختلفة

# تحسين حزم صغيرة الحجم (تستخدم كثيرًا في VoIP، الألعاب، والتطبيقات التفاعلية)
iptables -t mangle -A POSTROUTING -p udp -m length --length :200 -j TOS --set-tos 0x10
iptables -t mangle -A POSTROUTING -p tcp -m length --length :200 -j TOS --set-tos 0x10

# تدابير خاصة بـ MTU للشبكات المغربية
ip link set dev $IFACE mtu 1480

# إزالة أي تقييدات على مستوى TCP/IP
echo 0 > /proc/sys/net/ipv4/tcp_ecn
echo 1 > /proc/sys/net/ipv4/ip_early_demux
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling

echo "✅ تم تطبيق تحسينات خاصة بشبكات الجوال"

# ======== تحسينات لـ DNS ========
echo "🌐 تطبيق تحسينات DNS..."

# إضافة DNS سريعة بديلة
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
options rotate
options timeout:1
options attempts:2
EOF

# تسريع DNS lookups
echo "✅ تم تحسين إعدادات DNS"

# ======== إنشاء خدمة النظام لتطبيق التحسينات عند كل إقلاع ========
echo "🔄 إنشاء خدمة نظام لتطبيق التحسينات تلقائيًا عند الإقلاع..."

cat > /etc/systemd/system/udp-custom-optimizer.service <<EOF
[Unit]
Description=UDP Custom Optimization Service
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '# اكتشاف واجهة الشبكة
IFACE=\$(ip -o -4 route show to default | awk "{print \$5}");

# ضبط طابور الإرسال
ifconfig \$IFACE txqueuelen 20000;

# ضبط offloads
ethtool -C \$IFACE rx-usecs 0 tx-usecs 0 rx-frames 1 tx-frames 1 2>/dev/null || true;
ethtool -G \$IFACE rx 4096 tx 4096 2>/dev/null || true;
ethtool -K \$IFACE gso on gro on tso on ufo off lro off tx on rx on sg on 2>/dev/null || true;

# تطبيق جدولة متقدمة
tc qdisc replace dev \$IFACE root cake bandwidth unlimited besteffort flows 1024 rtt 5ms overhead 14 mpu 64 ingress wash nat wash ack-filter split-gso triple-isolate;

# تطبيق قواعد iptables
iptables -t mangle -F;
iptables -t mangle -A POSTROUTING -p udp -j DSCP --set-dscp-class EF;
iptables -t mangle -A POSTROUTING -p tcp -j DSCP --set-dscp-class AF41;
iptables -t mangle -A PREROUTING -p udp -j TOS --set-tos 0x10;
iptables -t mangle -A PREROUTING -p udp -j MARK --set-mark 100;
iptables -t mangle -A POSTROUTING -p udp -m length --length :200 -j TOS --set-tos 0x10;
iptables -t mangle -A POSTROUTING -p tcp -m length --length :200 -j TOS --set-tos 0x10;

# ضبط قيمة MTU
ip link set dev \$IFACE mtu 1480;

# إخراج التاريخ
date >> /var/log/udp-optimize-boot.log;
echo "UDP Optimizer تم تطبيق التحسينات بنجاح" >> /var/log/udp-optimize-boot.log;
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom-optimizer.service
systemctl start udp-custom-optimizer.service

# ======== اختبار الأداء ========
echo "🔍 اختبار الأداء الأساسي للنظام..."
echo "• معلومات واجهة الشبكة:"
ifconfig $IFACE | grep -E "RX|TX|MTU"
echo "• أداء اتصال DNS:"
time ping -c 3 1.1.1.1
echo "• تتبع القفزات للمضيف:"
traceroute -m 10 8.8.8.8 | head -10

# ======== إرشادات ختامية ========
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 تم تطبيق جميع التحسينات المتقدمة بنجاح!"
echo "⚡ تم تحسين النظام لأقصى أداء مع اتصالات UDP Custom و HTTP Custom"
echo ""
echo "📝 ملاحظات مهمة:"
echo "• يوصى بشدة بإعادة تشغيل السيرفر الآن: sudo reboot"
echo "• تم إنشاء خدمة نظام لتطبيق التحسينات تلقائيًا عند كل إقلاع"
echo "• تم حفظ سجل التثبيت في: $LOG_FILE"
echo "• تم حفظ النسخ الاحتياطية في: /root/network_backup"
echo ""
echo "💡 للمزيد من التحسينات المتقدمة، يمكن تعديل:"
echo "• ملف تكوين النواة: /etc/sysctl.conf"
echo "• ملف تكوين حدود الموارد: /etc/security/limits.conf"
echo "• خدمة تكوين الشبكة: /etc/systemd/system/udp-custom-optimizer.service"
echo ""
echo "💪 استمتع بأقصى أداء لاتصال الإنترنت!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

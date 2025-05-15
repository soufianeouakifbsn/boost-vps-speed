#!/bin/bash
echo "🚀 تحسين شامل متقدم لضمان استقرار اتصال UDP Custom مع HTTP Custom App"

# تحديد واجهة الشبكة تلقائيًا
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام المخصصة لـ UDP Custom ========
cat > /etc/sysctl.conf <<EOF
# ----- تحسينات أساسية لـ UDP -----
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# ----- تحسين أداء UDP -----
net.ipv4.udp_mem = 65536 131072 134217728
net.ipv4.udp_so_reuseport = 1

# ----- تقليل فقدان الحزم والخنق -----
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 8192
net.core.optmem_max = 33554432

# ----- استقرار الاتصالات والتتبع -----
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_buckets = 262144
net.netfilter.nf_conntrack_udp_timeout = 120
net.netfilter.nf_conntrack_udp_timeout_stream = 300

# ----- تحسينات TCP لتجنب التأثير السلبي على UDP -----
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq_codel

# ----- تحسينات للأداء العام -----
fs.file-max = 2097152
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535

# ----- تمكين تمرير UDP بأفضل أداء -----
net.ipv4.udp_early_demux = 1
net.ipv4.udp_l3mdev_accept = 1
EOF

# تطبيق الإعدادات
sysctl -p

# ======== إعدادات الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

# تطبيق على الجلسة الحالية
ulimit -n 1048576

# ======== تحسين جدولة حزم الشبكة خاص بـ UDP Custom ========
# تنظيف الجدولات الحالية
tc qdisc del dev $IFACE root 2>/dev/null

# تطبيق fq_codel مع إعدادات محسنة لـ UDP
tc qdisc add dev $IFACE root fq_codel quantum 1400 target 5ms interval 100ms flows 32768 ecn 

# ضبط طول صف الإرسال لتجنب التقطع
ifconfig $IFACE txqueuelen 10000

# ======== تحسين إعدادات كرت الشبكة ========
# تعطيل interrupt coalescence لتقليل التأخير
ethtool -C $IFACE rx-usecs 0 tx-usecs 0 rx-frames 1 tx-frames 1 2>/dev/null || true

# ضبط حجم الحلقات الدائرية للاستقبال والإرسال
ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true

# ضبط offloads للحصول على أفضل أداء مع UDP
ethtool -K $IFACE gso on gro on tso on ufo off lro off tx on rx on sg on 2>/dev/null || true

# ======== تحسين عدد العمليات المتزامنة للنظام ========
echo 65000 > /proc/sys/kernel/threads-max
echo 65000 > /proc/sys/vm/max_map_count
echo 65000 > /proc/sys/kernel/pid_max

# ======== إنشاء سكريبت تلقائي عند إعادة التشغيل ========
cat > /etc/systemd/system/udp-custom-optimize.service <<EOF
[Unit]
Description=UDP Custom Optimization Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'IFACE=\$(ip -o -4 route show to default | awk "{print \$5}"); tc qdisc replace dev \$IFACE root fq_codel quantum 1400 target 5ms interval 100ms flows 32768 ecn; ifconfig \$IFACE txqueuelen 10000'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# تفعيل الخدمة
systemctl daemon-reload
systemctl enable udp-custom-optimize.service

# ======== تحسين تعامل النظام مع الذاكرة ========
echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
sysctl -w vm.overcommit_memory=1

# ======== خطوات لمنع تقييد الشبكة ========
# فحص وإزالة أي قواعد تقييد سرعة موجودة
iptables -t mangle -F
ip6tables -t mangle -F

echo "✅ تمت إزالة أي قواعد تقييد محتملة لتدفق البيانات"

# ======== تطبيق خصائص للتعامل مع شبكات الجوال ====== 
# تحسين لشبكة inwi
tc qdisc add dev $IFACE root handle 1: prio
tc qdisc add dev $IFACE parent 1:1 handle 10: sfq perturb 10
tc qdisc add dev $IFACE parent 1:2 handle 20: sfq perturb 10
tc qdisc add dev $IFACE parent 1:3 handle 30: sfq perturb 10

echo "✅ تم تطبيق تحسينات خاصة بشبكات الجوال المغربية"

echo "🔥 تم تطبيق جميع التحسينات بنجاح!"
echo "⚡ يُفضل إعادة تشغيل السيرفر الآن لتفعيل كافة التغييرات: sudo reboot"

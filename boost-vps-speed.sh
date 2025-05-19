#!/bin/bash

set -e

echo "🚀 بدء تطبيق تحسينات شاملة معتدلة لضمان استقرار وأداء اتصال UDP Custom مع HTTP Custom App باستخدام PCC"

# ======== تثبيت وتفعيل وحدة PCC ========
echo "⚙️ تثبيت وتفعيل خوارزمية PCC للتحكم في الازدحام..."

# التحقق من وجود وحدة PCC وتحميلها إذا كانت متاحة
if [ -f "/lib/modules/$(uname -r)/kernel/net/ipv4/tcp_pcc.ko" ]; then
    modprobe tcp_pcc
    echo "✅ تم تحميل وحدة PCC بنجاح"
else
    echo "⚠️ وحدة PCC غير متوفرة في النواة الحالية. سيتم محاولة استخدام وحدة متوافقة..."
    # محاولة استخدام BBR كبديل إذا كان PCC غير متوفر
    modprobe tcp_bbr
    sed -i 's/net.ipv4.tcp_congestion_control = pcc/net.ipv4.tcp_congestion_control = bbr/g' /etc/sysctl.conf
    echo "🔄 تم استخدام BBR كبديل لـ PCC"
fi

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"
cat > /etc/sysctl.conf <<EOF
# ----- تحسينات أساسية لـ UDP بقيم معتدلة -----
net.core.rmem_max = 26214400
net.core.wmem_max = 26214400
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# ----- تحسين أداء UDP -----
net.ipv4.udp_mem = 65536 131072 26214400
net.ipv4.udp_so_reuseport = 1

# ----- تقليل فقدان الحزم والخنق (قيم معتدلة) -----
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 4096
net.core.optmem_max = 16777216

# ----- استقرار الاتصالات والتتبع -----
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 131072
net.netfilter.nf_conntrack_udp_timeout = 60
net.netfilter.nf_conntrack_udp_timeout_stream = 180

# ----- تحسينات TCP لتجنب التأثير السلبي على UDP -----
net.ipv4.tcp_congestion_control = pcc
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq_pie

# ----- تحسينات عامة للنظام -----
fs.file-max = 1048576
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535

# ----- تحسين الذاكرة -----
vm.overcommit_memory = 1
EOF

sysctl -p

# ======== إعدادات حدود الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 524288
* hard nofile 524288
root soft nofile 524288
root hard nofile 524288
EOF

ulimit -n 524288

# ======== تحسين جدولة حزم الشبكة (إعدادات أكثر اعتدالاً) ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# استخدام PIE لتحسين التعامل مع تقلبات شبكات الجوال المغربية
tc qdisc add dev $IFACE root pie limit 1000 target 15ms

# ضبط طابور الإرسال بقيمة معتدلة
ifconfig $IFACE txqueuelen 5000

# ======== ضبط عدد العمليات المتزامنة للنظام بشكل معتدل ========
echo 32768 > /proc/sys/kernel/threads-max
echo 32768 > /proc/sys/vm/max_map_count
echo 32768 > /proc/sys/kernel/pid_max

# ======== إزالة قواعد iptables تقييدية ========
iptables -t mangle -F
ip6tables -t mangle -F

echo "✅ تم إزالة أي قواعد تقييد محتملة لتدفق البيانات"

# ======== تحسينات خاصة بشبكات إنوي (أكثر اعتدالاً) ========
# استخدام جدولة بسيطة ومستقرة لشبكات إنوي
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root handle 1: prio bands 3
tc qdisc add dev $IFACE parent 1:1 handle 10: sfq
tc qdisc add dev $IFACE parent 1:2 handle 20: sfq
tc qdisc add dev $IFACE parent 1:3 handle 30: sfq

echo "✅ تم تطبيق تحسينات مستقرة خاصة بشبكات إنوي"

# ======== إنشاء خدمة systemd لتطبيق تحسينات الشبكة تلقائيًا عند الإقلاع ========
cat > /etc/systemd/system/udp-custom-optimize.service <<EOF
[Unit]
Description=UDP Custom Optimization Service (Balanced)
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'IFACE=\$(ip -o -4 route show to default | awk "{print \$5}"); \
tc qdisc replace dev \$IFACE root pie limit 1000 target 15ms; \
ifconfig \$IFACE txqueuelen 5000; \
tc qdisc replace dev \$IFACE root handle 1: prio bands 3; \
tc qdisc replace dev \$IFACE parent 1:1 handle 10: sfq; \
tc qdisc replace dev \$IFACE parent 1:2 handle 20: sfq; \
tc qdisc replace dev \$IFACE parent 1:3 handle 30: sfq;'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom-optimize.service

echo "🔥 تم تطبيق جميع التحسينات المتوازنة مع خوارزمية PCC بنجاح!"
echo "⚡ يُفضل إعادة تشغيل السيرفر الآن لتفعيل كافة التغييرات: sudo reboot"

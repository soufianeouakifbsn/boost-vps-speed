#!/bin/bash
set -e

IFACE=$(ip -o -4 route show to default | awk '{print $5}')
MODPROBE="/etc/modprobe.d/tuning.conf"
GRUB="/etc/default/grub"

# إعدادات أساسية أكثر استقرارًا
cat > /etc/sysctl.conf <<EOF
# إعدادات الذاكرة الأساسية
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576

# تحسينات TCP
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_frto = 2

# إعدادات الشبكة العامة
net.core.netdev_max_backlog = 3000
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2

# تحسينات الأمان والأداء
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 2097152
EOF

sysctl -p

# إعدادات متقدمة للشبكة
ip link set dev $IFACE txqueuelen 1000
ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
ethtool -K $IFACE gro on gso on tso on 2>/dev/null || true

# تكوين GRUB لإعدادات CPU
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& mitigations=off processor.max_cstate=1 intel_idle.max_cstate=0 idle=poll/' $GRUB
update-grub 2>/dev/null || true

# إعدادات مودبروب
cat > $MODPROBE <<EOF
options ixgbe IntMode=1 RSS=1
options i40e debug=1
options mlx4_core log_num_mgm_entry_size=-1
EOF

# تحسينات IRQ
if systemctl is-active --quiet irqbalance; then
    systemctl stop irqbalance
    systemctl disable irqbalance
fi

for irq in /proc/irq/*; do
    echo 1 > "$irq/smp_affinity" 2>/dev/null || true
done

# إعدادات الطاقة
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > $cpu 2>/dev/null || true
done

# إعدادات نظام الملفات
cat >> /etc/fstab <<EOF
noatime,nodiratime,commit=60,barrier=0,data=writeback,discard
EOF

# إعادة تعيين إعدادات الشبكة
tc qdisc del dev $IFACE root 2>/dev/null || true
tc qdisc add dev $IFACE root fq_codel

echo "✅ تم التثبيت بنجاح مع تحسين الاستقرار!"
echo "يرجى إعادة التشغيل لتفعيل جميع الإعدادات: reboot"

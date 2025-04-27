#!/bin/bash
# سكربت ضبط إعدادات sysctl متقدمة لتحسين أداء UDP/ZIVPN 🚀⚡

echo "🔧 تطبيق إعدادات شبكة مخصصة لـ UDP/ZIVPN..."

# كتابة الإعدادات إلى sysctl.conf
cat > /etc/sysctl.conf <<EOF
# ==== تحسين أساسي للشبكة ====
net.core.rmem_default = 16777216
net.core.rmem_max = 268435456
net.core.wmem_default = 16777216
net.core.wmem_max = 268435456

# ==== إعدادات UDP المتقدمة ====
net.ipv4.udp_rmem_min = 8192000
net.ipv4.udp_wmem_min = 8192000
net.ipv4.udp_mem = 786432 1048576 268435456

# ==== تحسين معالجة الحزم ====
net.core.netdev_max_backlog = 500000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 5000
net.core.busy_read = 50
net.core.busy_poll = 50

# ==== تحسينات النظام ====
fs.file-max = 4194304
fs.nr_open = 4194304

# ==== تحسينات أداء الشبكة ====
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.ip_forward = 1

# ==== تحسينات زمن الاستجابة ====
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 2

# ==== تحسينات الذاكرة ====
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
EOF

# تطبيق التعديلات فوراً
sysctl -p

echo "✅ تم تطبيق إعدادات sysctl المتقدمة!"

# ضبط حدود النظام القصوى
echo "🔧 رفع حدود النظام إلى أقصى قيمة..."

cat > /etc/security/limits.d/99-zivpn.conf <<EOF
# ==== حدود ملفات ZIVPN ====
* soft nofile 2097152
* hard nofile 4194304
* soft memlock unlimited
* hard memlock unlimited
* soft nproc  unlimited
* hard nproc  unlimited
EOF

# إعدادات إضافية للشبكة
echo "🔧 تهيئة إعدادات IRQ Balance..."
for irq in /proc/irq/*/smp_affinity; do
    echo 7 > "$irq" 2>/dev/null
done
echo 32768 > /proc/sys/net/core/rps_sock_flow_entries

echo "✅ تم ضبط إعدادات IRQ وRPS!"

# نصيحة نهائية
echo ""
echo "🚀⚡ التهيئة الكاملة تمت بنجاح!"
echo "لأفضل أداء:"
echo "1. أعد تشغيل السيرفر: reboot"
echo "2. تأكد من تفعيل UDP Acceleration في ZIVPN"
echo "3. استخدم أحدث إصدار من ZIVPN على الهاتف"

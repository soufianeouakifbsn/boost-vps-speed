#!/bin/bash
# سكربت ضبط إعدادات sysctl لتحسين سرعة الأبلود وتحسين الأداء على الشبكات الضعيفة 📶🚀

echo "🔧 تطبيق إعدادات متقدمة للشبكة والمخرجات..."

# كتابة الإعدادات إلى sysctl.conf
cat > /etc/sysctl.conf <<EOF
# ==== تحسين أداء الشبكة ====

# تخصيص ذاكرة TCP
net.core.rmem_default = 262144
net.core.rmem_max = 536870912
net.core.wmem_default = 262144
net.core.wmem_max = 536870912

# تخصيص ذاكرة TCP أثناء النقل
net.ipv4.tcp_rmem = 4096 87380 536870912
net.ipv4.tcp_wmem = 4096 65536 536870912

# حجم قائمة الانتظار في كرت الشبكة
net.core.netdev_max_backlog = 500000
net.core.somaxconn = 65535

# استخدام TCP BBR لتحسين الأداء على الشبكات الضعيفة
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# تحسين التوافقية مع شبكات متنقلة
net.ipv4.tcp_mtu_probing = 1

# تقليل الاتصالات المعلقة
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1

# تفعيل TCP Fast Open
net.ipv4.tcp_fastopen = 3

# تحسين أداء NAT والاتصال الداخلي
net.ipv4.ip_forward = 1
net.netfilter.nf_conntrack_max = 1048576

# تعيين مجال المنافذ المحلي
net.ipv4.ip_local_port_range = 1024 65535

# تعطيل التحويلات والتوجيهات غير الضرورية
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# تحسين الأداء والتوافق مع VPN/4G
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_ecn = 0

# ==== تحسين أداء النظام ====

# رفع حد الملفات المفتوحة
fs.file-max = 2097152

# رفع مراقبة inotify (للتطبيقات كثيرة الملفات)
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 1048576

# تحسين إدارة الذاكرة
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
EOF

# تطبيق التعديلات
sysctl -p

echo "✅ تم تطبيق إعدادات sysctl بنجاح!"

# ضبط حدود الملفات المفتوحة (ulimit)
echo "🔧 رفع حدود الملفات المفتوحة..."

ulimit -n 1048576

# تعديل limits.conf
cat >> /etc/security/limits.conf <<EOF

# ==== رفع حدود الملفات المفتوحة ====
* soft nofile 1048576
* hard nofile 1048576
EOF

# تعديل pam limits
if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
  echo "session required pam_limits.so" >> /etc/pam.d/common-session
fi

# تعديل systemd limits
mkdir -p /etc/systemd/system.conf.d/
cat > /etc/systemd/system.conf.d/99-custom.conf <<EOF
[Manager]
DefaultLimitNOFILE=1048576
EOF

mkdir -p /etc/systemd/user.conf.d/
cat > /etc/systemd/user.conf.d/99-custom.conf <<EOF
[Manager]
DefaultLimitNOFILE=1048576
EOF

echo "✅ تم تعديل إعدادات systemd وlimits بنجاح!"

# نصيحة ختامية
echo ""
echo "🚀 تم تحسين إعدادات النظام والشبكة لأقصى أداء ممكن في الشبكات الضعيفة!"
echo "🔄 يُنصح بإعادة تشغيل السيرفر لتفعيل كل التعديلات."
echo "🖥️ استخدم الأمر التالي لإعادة التشغيل: sudo reboot"

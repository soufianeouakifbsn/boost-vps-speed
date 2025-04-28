#!/bin/bash
# سكربت ضبط إعدادات sysctl لتحسين سرعة الأبلود 🚀

echo "🔧 تطبيق إعدادات متقدمة للشبكة..."

# كتابة الإعدادات إلى sysctl.conf
cat > /etc/sysctl.conf <<EOF
# ==== تحسين الشبكة ====

net.core.rmem_default = 8388608
net.core.rmem_max = 67108864
net.core.wmem_default = 8388608
net.core.wmem_max = 67108864

net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

net.core.netdev_max_backlog = 250000
net.core.somaxconn = 65535

net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_window_scaling = 1

net.ipv4.tcp_fastopen = 3

net.ipv4.ip_local_port_range = 1024 65535

net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_timestamps = 1

# ==== تحسين النظام ====

fs.file-max = 2097152
EOF

# تطبيق التعديلات
sysctl -p

echo "✅ تم تطبيق إعدادات sysctl بنجاح!"

# ضبط حدود الملفات المفتوحة (ulimit)
echo "🔧 رفع حدود الملفات المفتوحة..."

ulimit -n 1048576

# إضافة للملفات الدائمة
cat >> /etc/security/limits.conf <<EOF

# ==== رفع حدود الملفات المفتوحة ====
* soft nofile 1048576
* hard nofile 1048576
EOF

echo "✅ تم ضبط limits.conf بنجاح!"

# نصيحة
echo ""
echo "🚀 كل شيء جاهز! من الأفضل أن تعيد تشغيل السيرفر لضمان تطبيق كل شيء بكفاءة."
echo "لإعادة تشغيل السيرفر الآن اكتب: reboot"

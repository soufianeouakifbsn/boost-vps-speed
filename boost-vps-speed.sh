#!/bin/bash
# سكربت لتحسين سرعة الإنترنت مع تقليل الاختناق 🚀

echo "🔧 تطبيق إعدادات محسنة لتحسين الشبكة..."

# إعادة كتابة الإعدادات إلى sysctl.conf مع تعديلات جديدة
cat > /etc/sysctl.conf <<EOF
# ==== تحسين الشبكة ====

# تخصيص ذاكرة TCP و UDP مع تقليل الحجم
net.core.rmem_default = 16777216
net.core.rmem_max = 67108864
net.core.wmem_default = 16777216
net.core.wmem_max = 67108864

# تخصيص ذاكرة TCP أثناء النقل
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# تخصيص ذاكرة UDP
net.core.rmem_default = 16777216
net.core.rmem_max = 67108864
net.core.wmem_default = 16777216
net.core.wmem_max = 67108864

# تخصيص حجم قائمة الانتظار للـ TCP
net.core.netdev_max_backlog = 200000
net.core.somaxconn = 32768

# استخدام TCP Cubic لتحسين الأداء
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_window_scaling = 1

# تفعيل TCP Fast Open لتسريع الاتصال
net.ipv4.tcp_fastopen = 3

# تخصيص المجال المحلي للمنافذ
net.ipv4.ip_local_port_range = 1024 65535

# تقليل وقت الانتظار في TCP
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1

# تعطيل إعادة التوجيه في الشبكة
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# تحسين الأداء في TCP
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_timestamps = 0

# تحسين استقرار الاتصال
net.ipv4.ip_forward = 1

# ==== تحسين النظام ====

# زيادة حد الملفات المفتوحة
fs.file-max = 2097152

# تخصيص الحد الأقصى لعدد العمليات
fs.inotify.max_user_watches = 524288

# تخصيص الذاكرة الافتراضية
vm.swappiness = 10
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

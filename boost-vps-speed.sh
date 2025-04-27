#!/bin/bash
# سكربت لتحسين سرعة الداونلود مع الحفاظ على الأبلود 🚀

echo "🔧 تطبيق إعدادات تعزيز سرعة الداونلود..."

# إعادة كتابة الإعدادات إلى sysctl.conf
cat > /etc/sysctl.conf <<EOF
# ==== تحسين الشبكة ====

# تخصيص ذاكرة TCP و UDP للداونلود بشكل كبير
net.core.rmem_default = 134217728
net.core.rmem_max = 268435456
net.core.wmem_default = 134217728
net.core.wmem_max = 268435456

# تخصيص ذاكرة TCP أثناء النقل للداونلود
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456

# تخصيص ذاكرة UDP للداونلود
net.core.rmem_default = 134217728
net.core.rmem_max = 268435456
net.core.wmem_default = 134217728
net.core.wmem_max = 268435456

# تخصيص حجم قائمة الانتظار للـ TCP
net.core.netdev_max_backlog = 500000
net.core.somaxconn = 65536

# استخدام خوارزمية BBR مع تحسينات للداونلود
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_window_scaling = 1

# تفعيل الذاكرة المستلمة (RECVBUF) لمزيد من التحميل
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456

# تقليل وقت الانتظار في TCP لتحسين استجابة الداونلود
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1

# تحسين الاتصال الداخلي
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.ip_forward = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_timestamps = 0

# تحسين أداء الداونلود
net.ipv4.tcp_low_latency = 1
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

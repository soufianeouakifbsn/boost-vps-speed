#!/bin/bash
echo "🔧 تطبيق تحسينات متقدمة جدًا للشبكة والأداء..."

# تحسين TCP و UDP
cat > /etc/sysctl.conf <<EOF
# تخصيص ذاكرة أكبر لاستقبال وإرسال البيانات
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# تفعيل BBR بدلاً من Cubic
net.ipv4.tcp_congestion_control = bbr

# ضبط MTU للحصول على أداء أقصى
net.core.default_qdisc = fq
net.ipv4.tcp_mtu_probing = 2

# زيادة الأداء في إرسال واستقبال الحزم
net.ipv4.tcp_rmem = 8192 262144 536870912
net.ipv4.tcp_wmem = 8192 262144 536870912

# تحسين إعدادات الشبكة العامة
net.core.netdev_max_backlog = 1000000
net.core.somaxconn = 131072
EOF

# تطبيق التعديلات
sysctl -p

# رفع حدود الملفات المفتوحة
ulimit -n 2097152

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 2097152
* hard nofile 2097152
EOF

echo "✅ تم تطبيق كافة التحسينات بنجاح! 🚀"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل أداء."


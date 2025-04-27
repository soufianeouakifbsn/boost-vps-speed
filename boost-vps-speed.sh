#!/bin/bash
# سكربت مُعدَّل لضبط إعدادات sysctl ومحاولة تمويه اتصالات UDP (يتطلب تكوين VPN منفصل) 🚀

echo "🔧 تطبيق إعدادات متقدمة للشبكة ومحاولة تمويه UDP..."

# ==== تحسين الشبكة (مع التركيز على تقليل الخصائص المميزة) ====

# قيم ذاكرة TCP (قد تحتاج إلى تعديل هذه القيم بناءً على إعدادات VPN الخاصة بك)
net.core.rmem_default = 2097152
net.core.rmem_max = 33554432
net.core.wmem_default = 2097152
net.core.wmem_max = 33554432

net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432

# حجم قائمة الانتظار
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 65536

# التحكم في الازدحام (قد تحتاج إلى تجربة خوارزميات مختلفة)
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control = cubic # أو bbr أو غيرها

net.ipv4.tcp_mtu_probing = 0 # تعطيل probing لتقليل الأنماط المميزة
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_window_scaling = 1

# TCP Fast Open
net.ipv4.tcp_fastopen = 3

# نطاق المنافذ المحلية
net.ipv4.ip_local_port_range = 1024 65535

# مهلات TCP (قيم متحفظة)
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0 # تعطيل recycle لتجنب مشاكل NAT

# تعطيل إعادة التوجيه
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# تحسينات TCP
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1

net.core.optmem_max = 2048000
net.ipv4.tcp_slow_start_after_idle = 0

# تعطيل IPv6 إذا كنت لا تستخدمه (يمكن أن يقلل من التعقيد)
net.ipv6.conf.all.disable_ipv6 = 1

# ==== إعدادات محتملة لتمويه UDP (قد لا تكون كلها ضرورية أو مدعومة افتراضيًا) ====

# **ملاحظة هامة:** هذه الإعدادات أدناه هي مفاهيمية وقد لا يكون لها تأثير مباشر على تمويه UDP
# على مستوى sysctl. تمويه UDP يتم تحقيقه بشكل أساسي بواسطة برنامج VPN نفسه.

echo "⚠️ **تحذير:** إعدادات تمويه UDP تعتمد بشكل كبير على برنامج VPN المستخدم."
echo "   هذه الإعدادات أدناه هي مفاهيمية وقد لا يكون لها تأثير مباشر."
echo ""

# قد تحاول بعض برامج التعتيم تعديل حجم الحزمة (MTU/MSS)
# ومع ذلك، يجب التعامل مع هذه الإعدادات بحذر لتجنب مشاكل التجزئة.
# net.ipv4.tcp_mtu_probing = 0
# net.ipv4.tcp_base_mss = 1400 # مثال لقيمة MSS

# بعض التقنيات قد تتضمن تعديل علامات TCP (لا ينطبق مباشرة على UDP)
# net.ipv4.tcp_synack_retries = 2

# ==== تحسينات النظام العامة ====

fs.file-max = 1048576
fs.inotify.max_user_watches = 524288
vm.swappiness = 10

# تطبيق التعديلات
sudo sysctl -p

echo "✅ تم تطبيق إعدادات sysctl بنجاح (مع محاولة تمويه UDP - مفاهيمية)!"

# ضبط حدود الملفات المفتوحة (ulimit)
echo "🔧 رفع حدود الملفات المفتوحة..."

sudo ulimit -n 1048576

# إضافة للملفات الدائمة
sudo cat >> /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
EOF

echo "✅ تم ضبط limits.conf بنجاح!"

echo ""
echo "💡 **هام:** تمويه اتصالات UDP يتم بشكل أساسي بواسطة برنامج VPN الذي تستخدمه."
echo "   تحقق من إعدادات برنامج VPN الخاص بك وابحث عن خيارات مثل Obfuscation، Scramble،"
echo "   أو استخدام بروتوكولات مثل Shadowsocks أو Obfsproxy كوكيل لـ OpenVPN."
echo ""
echo "   هذه الإعدادات في sysctl قد تساعد في تقليل بعض الخصائص المميزة للاتصال،"
echo "   لكن التمويه الحقيقي يحدث على مستوى تطبيق VPN."
echo ""
echo "🚀 أعد تشغيل الخادم لتطبيق التغييرات."
echo "لإعادة تشغيل الخادم الآن اكتب: sudo reboot"

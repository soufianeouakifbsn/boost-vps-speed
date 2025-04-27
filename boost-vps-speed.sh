#!/bin/bash
# سكربت مُعدَّل إضافيًا لضبط إعدادات sysctl وتحسين الأداء (محاولة أكثر جذرية) 🚀

echo "🔧 تطبيق إعدادات متقدمة للشبكة (محاولة أكثر جذرية)..."

# كتابة الإعدادات إلى sysctl.conf
cat > /etc/sysctl.conf <<EOF
# ==== تحسين الشبكة (تركيز قوي على الأداء والاستجابة) ====

# تخصيص ذاكرة TCP (قيم أعلى لزيادة قدرة الاستيعاب)
net.core.rmem_default = 33554432
net.core.rmem_max = 268435456
net.core.wmem_default = 33554432
net.core.wmem_max = 268435456

# تخصيص ذاكرة TCP أثناء النقل (قيم أعلى لتدفق بيانات أفضل)
net.ipv4.tcp_rmem = 4096 174760 268435456
net.ipv4.tcp_wmem = 4096 219000 268435456

# تخصيص حجم قائمة الانتظار للـ TCP (قيمة عالية جدًا لتحمل الازدحام الشديد)
net.core.netdev_max_backlog = 2000000
net.core.somaxconn = 65536

# استخدام TCP BBRv2 (خوارزمية أحدث وأكثر عدوانية لتحسين الإنتاجية وتقليل زمن الوصول)
# تأكد من أن نواة نظامك تدعم هذه الخوارزمية.
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control = bbr2
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 7440

net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_window_scaling = 1

# تفعيل TCP Fast Open لتسريع الاتصال
net.ipv4.tcp_fastopen = 3

# تخصيص المجال المحلي للمنافذ (نطاق واسع)
net.ipv4.ip_local_port_range = 1024 65535

# تقليل وقت الانتظار في TCP (قيم أكثر عدوانية لتحرير الموارد بسرعة)
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1

# تعطيل بعض الميزات التي قد تسبب حملًا إضافيًا
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.disable_ipv6 = 1 # تعطيل IPv6 إذا كنت لا تستخدمه

# تحسين الأداء في TCP
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1 # تفعيل Selective Acknowledgements

# قيم إضافية لتحسين الأداء
net.core.optmem_max = 2048000
net.ipv4.tcp_slow_start_after_idle = 0
EOF

# تطبيق التعديلات
sudo sysctl -p

echo "✅ تم تطبيق إعدادات sysctl بنجاح (محاولة أكثر جذرية)!"

# ضبط حدود الملفات المفتوحة (ulimit)
echo "🔧 رفع حدود الملفات المفتوحة..."

sudo ulimit -n 2097152

# إضافة للملفات الدائمة
sudo cat >> /etc/security/limits.conf <<EOF

# ==== رفع حدود الملفات المفتوحة ====
* soft nofile 2097152
* hard nofile 2097152
EOF

echo "✅ تم ضبط limits.conf بنجاح!"

echo ""
echo "⚠️ **تحذير هام:** هذه الإعدادات أكثر عدوانية وقد لا تكون مناسبة لجميع الأنظمة أو الشبكات."
echo "   راقب أداء النظام والشبكة بعناية بعد إعادة التشغيل."
echo ""

# أدوات تشخيصية مقترحة:
echo "🛠️ **أدوات تشخيصية قد تساعدك:**"
echo "1. **ping:** لاختبار زمن الوصول والاتصال بالخوادم البعيدة:"
echo "   \`ping -c 10 google.com\` أو \`ping -c 10 your_isp_router_ip\`"
echo "2. **traceroute (أو tracert على ويندوز):** لتتبع المسار الذي تسلكه الحزم إلى وجهة معينة:"
echo "   \`traceroute google.com\`"
echo "3. **speedtest-cli:** أداة سطر أوامر لاختبار سرعة الإنترنت الخاصة بك (قد تحتاج إلى تثبيتها):"
echo "   \`sudo apt update && sudo apt install speedtest-cli\` ثم \`speedtest-cli\`"
echo "4. **iftop:** لعرض استخدام النطاق الترددي في الوقت الفعلي لكل اتصال (قد تحتاج إلى تثبيتها):"
echo "   \`sudo apt update && sudo apt install iftop\` ثم \`sudo iftop\`"
echo "5. **sar (System Activity Reporter):** لمراقبة أداء الشبكة واستخدام الموارد:"
echo "   \`sar -n DEV 1 5\` (لمراقبة واجهات الشبكة)"

echo ""
echo "💡 **نصائح إضافية:**"
echo "- تأكد من أن برنامج تشغيل بطاقة الشبكة لديك هو الأحدث."
echo "- تحقق من إعدادات جهاز التوجيه (الراوتر) الخاص بك وتأكد من أنه يعمل بشكل صحيح وليس هناك أي قيود على النطاق الترددي."
echo "- قد تكون هناك عوامل أخرى تؤثر على سرعة الإنترنت لديك خارج نطاق إعدادات نظامك (مثل ازدحام الشبكة لدى مزود الخدمة)."

echo ""
echo "🚀 كل شيء جاهز! من الضروري إعادة تشغيل السيرفر الآن لتطبيق هذه التغييرات."
echo "لإعادة تشغيل السيرفر الآن اكتب: sudo reboot"

#!/bin/bash
# سكربت تثبيت السرعة القصوى مع استقرار توربيني 🔥

echo "🌀 بدء التهيئة الذكية للاستقرار والسرعة..."

# ===== إعدادات sysctl المتوازنة =====
cat > /etc/sysctl.conf <<EOF
# 🔄 إعدادات الذاكرة الديناميكية
net.core.rmem_default = 16777216
net.core.rmem_max = 67108864
net.core.wmem_default = 16777216
net.core.wmem_max = 67108864
net.core.optmem_max = 65536

# ⚖️ توازن UDP الذكي
net.ipv4.udp_rmem_min = 8192000
net.ipv4.udp_wmem_min = 8192000
net.ipv4.udp_mem = 8192000 16777216 33554432

# 🧠 معالجة حزم متقدمة
net.core.netdev_max_backlog = 300000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 8000
net.core.busy_poll = 50
net.core.busy_read = 40

# 🛡️ تحسينات الاستقرار
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_workaround_signed_windows = 1

# 🔄 إدارة الذاكرة المحسنة
vm.swappiness = 10
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
EOF

sysctl -p

# ===== إعدادات NIC المتوازنة =====
echo "🔧 ضبط إعدادات الشبكة الذكية..."
for dev in $(ls /sys/class/net/); do
    ethtool -G $dev rx 2048 tx 2048 2>/dev/null
    ethtool -K $dev gro on gso on tso on 2>/dev/null
    ethtool -C $dev rx-usecs 100 tx-usecs 100 2>/dev/null
    ip link set $dev txqueuelen 10000 2>/dev/null
done

# ===== إدارة IRQ المتقدمة =====
echo "⚡ تحسين توزيع حمل المعالجة..."
for irq in /proc/irq/*/smp_affinity_list; do
    echo "0-3" > "$irq" 2>/dev/null
done

# ===== مراقبة الأداء التلقائية =====
echo "📊 تفعيل نظام المراقبة الذكية..."
cat > /usr/local/bin/network_monitor.sh <<EOF
#!/bin/bash
while true; do
    echo "==== $(date) ===="
    ifconfig | grep -A1 "eth\|enp"
    echo "Ping Test:"
    ping -c 4 8.8.8.8 | tail -n2
    echo "Speed Test:"
    speedtest-cli --simple
    echo "================="
    sleep 60
done
EOF

chmod +x /usr/local/bin/network_monitor.sh
nohup /usr/local/bin/network_monitor.sh > /var/log/network_monitor.log &

echo "✅ التهيئة الكاملة بنجاح! النظام يعمل الآن بأداء مستقر ⚡"

cat <<EOF

╔══════════════════════════════════╗
║        نصائح الاستخدام الذهبية:       ║
╠══════════════════════════════════╣
║ 1. تفقد سجلات المراقبة باستمرار:    ║
║    tail -f /var/log/network_monitor.log ║
║ 2. تأكد من عدم وجود تحديثات خلفية   ║
║ 3. اختبر مع خادم قريب جغرافياً     ║
║ 4. تفقد جودة الكابل والشبكة       ║
╚══════════════════════════════════╝
EOF#!/bin/bash
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

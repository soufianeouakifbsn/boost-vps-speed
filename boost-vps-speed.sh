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
EOF

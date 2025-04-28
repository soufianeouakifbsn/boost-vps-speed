#!/bin/bash
echo "🚀 تعزيز إعدادات الشبكة لتحقيق سرعة قصوى في التحميل والرفع عبر UDP! ⚡"

# تحسين إدارة الحزم عبر الشبكة
cat > /etc/sysctl.conf <<EOF
net.core.rps_sock_flow_entries = 4194304
net.core.netdev_max_backlog = 160000000

# تعزيز تدفق البيانات عبر UDP (تحميل ورفع بسرعة خارقة)
net.core.optmem_max = 17179869184
net.ipv4.udp_mem = 4194304 33554432 68719476736
net.ipv4.udp_rmem_min = 4194304
net.ipv4.udp_wmem_min = 4194304
net.ipv4.udp_rmem_max = 1073741824
net.ipv4.udp_wmem_max = 2147483648

# تحسين إدارة حركة المرور عبر الشبكة
net.core.default_qdisc = fq_codel  # تحسين الثبات عبر خوارزمية fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_ecn = 1

# تفعيل FQ-CoDel لتقليل زمن الانتظار هذه التقنية تقلل تأخير الشبكة وتحسن استجابة الاتصالات:
sysctl -w net.core.default_qdisc=fq_codel

#زيادة حجم مخزن UDP Buffer لمنع فقدان الحزم
sysctl -w net.ipv4.udp_rmem_max=2147483648
sysctl -w net.ipv4.udp_wmem_max=2147483648

# تحسين استجابة الشبكة عبر ضبط TCP/UDP
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3
EOF

sysctl -p

# ضبط إعدادات بطاقة الشبكة
echo "🔧 ضبط بطاقة الشبكة لتحقيق أقصى سرعة في التحميل والرفع!"
IFACE="eth0"
ethtool -G $IFACE rx 1048576 tx 1048576
ethtool -C $IFACE adaptive-rx off adaptive-tx off
ethtool -C $IFACE rx-usecs 0 tx-usecs 0
ethtool -K $IFACE tx-checksum-ipv4 off tx-checksum-ipv6 off tx-checksum-fcoe off
ethtool -A $IFACE rx off tx off
ethtool -s $IFACE speed 25000 duplex full autoneg off  # ضبط سرعة البطاقة إلى 25Gbps إن كانت تدعم ذلك!
ethtool -K $IFACE xdp on  # تفعيل XDP لتسريع معالجة الحزم داخل بطاقة الشبكة!

# ضبط MTU للحصول على تدفق ضخم للحزم
echo "📡 ضبط MTU إلى 9000 لزيادة حجم الإطارات الجامبو!"
ifconfig $IFACE mtu 9000

# تعزيز سرعة الرفع عبر UDP
echo "🔥 رفع سرعة الرفع عبر UDP إلى الحد الأقصى!"
ethtool -G $IFACE tx 2097152  # رفع المخزن المؤقت للإرسال

# ضبط استقرار اتصال الشبكة
echo "🔥 تحسين استقرار الشبكة عبر ضبط CPU Affinity!"
sysctl -w net.core.somaxconn=65535
sysctl -w net.core.netdev_max_backlog=500000

# تحسين استجابة المعالج لمعالجة الحزم
sysctl -w kernel.numa_balancing=1
sysctl -w kernel.numa_balancing_scan_delay_ms=500

# ضبط اتصال الـ MTU بشكل ديناميكي
sysctl -w net.ipv4.route_min_pmtu=1000
sysctl -w net.ipv4.tcp_mtu_probing=1

# ضبط حدود الملفات المفتوحة
ulimit -n 536870912

# تعديل الملفات الدائمة
cat >> /etc/security/limits.conf <<EOF
* soft nofile 536870912
* hard nofile 536870912
EOF

echo "✅ الشبكة الآن جاهزة لنقل البيانات بأقصى سرعة تحميل وأقصى سرعة رفع عبر UDP!"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

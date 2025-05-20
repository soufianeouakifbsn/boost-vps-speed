#!/bin/bash
set -e
echo "🚀 بدء تطبيق تحسينات متقدمة لتخفيض ping وتحسين استقرار اتصال UDP Custom مع HTTP Custom App"

# ======== تحديد واجهة الشبكة الافتراضية ========
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🔍 تم اكتشاف واجهة الشبكة: $IFACE"

# ======== تحسينات نواة النظام المركزة على تقليل زمن الاستجابة ========
cat > /etc/sysctl.conf <<EOF
# تحسينات الاستقرار ومنع التقطع
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 16777216 
net.core.wmem_default = 16777216
net.ipv4.udp_rmem_min = 32768
net.ipv4.udp_wmem_min = 32768
net.ipv4.udp_mem = 131072 262144 67108864
net.ipv4.udp_so_reuseport = 1
net.ipv4.udp_i_rmem_min = 32768
net.ipv4.udp_i_wmem_min = 32768

# تقليل التأخير (ping)
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 16384
net.core.optmem_max = 67108864
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_buckets = 262144
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120

# خوارزميات تحكم الازدحام المناسبة للاتصالات العالية التأخر
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_fastopen = 3

# تقليل عمليات إعادة الإرسال والتأخير
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.core.default_qdisc = fq_codel
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.ip_no_pmtu_disc = 1

# تحسين ذاكرة النظام للاتصالات
fs.file-max = 3145728
vm.swappiness = 1
vm.vfs_cache_pressure = 20
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.overcommit_memory = 1
vm.dirty_ratio = 3
vm.dirty_background_ratio = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_max_tw_buckets = 3000000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_retries2 = 4

# تحسينات إضافية لتقليل زمن الاستجابة
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF

sysctl -p

# ======== إعداد حدود الملفات المفتوحة ========
cat > /etc/security/limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

ulimit -n 1048576

# ======== إعداد توجيه حزم IPv4 لتقليل التأخر ========
echo "#!/bin/sh" > /etc/network/if-up.d/custom-routing
echo "ip route flush cache" >> /etc/network/if-up.d/custom-routing
chmod +x /etc/network/if-up.d/custom-routing

# ======== إزالة أي إعدادات شبكة سابقة لتجنب التعارض ========
tc qdisc del dev $IFACE root 2>/dev/null || true

# ======== إعداد جدولة الشبكة FQ_CODEL لتقليل latency وjitter ========
tc qdisc add dev $IFACE root handle 1: htb default 10
tc class add dev $IFACE parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit quantum 60000
tc class add dev $IFACE parent 1:1 classid 1:10 htb rate 900mbit ceil 1000mbit prio 0 quantum 60000
tc class add dev $IFACE parent 1:1 classid 1:20 htb rate 95mbit ceil 500mbit prio 1 quantum 60000

# استخدام fq_codel بدلاً من sfq للحصول على استقرار أفضل وتقليل latency
tc qdisc add dev $IFACE parent 1:10 handle 10: fq_codel limit 10240 target 5ms interval 30ms flows 4096 quantum 1514 ecn
tc qdisc add dev $IFACE parent 1:20 handle 20: fq_codel limit 10240 target 5ms interval 30ms flows 4096 quantum 1514 ecn

# تصفية الحزم وتوجيهها
tc filter add dev $IFACE parent 1: protocol ip prio 1 u32 match ip protocol 17 0xff flowid 1:10
tc filter add dev $IFACE parent 1: protocol ip prio 1 handle 10 fw flowid 1:10

# ======== تعيين طابور الإرسال وMTU المثالي ========
ip link set dev $IFACE txqueuelen 16000
ip link set dev $IFACE mtu 1500

# ======== إعداد iptables لحزم UDP مع أولوية عالية وتوسيم للتحكم في QoS ========
iptables -t mangle -F
ip6tables -t mangle -F
iptables -t mangle -N UDPMARKING 2>/dev/null || true
iptables -t mangle -F UDPMARKING
iptables -t mangle -D OUTPUT -p udp -j UDPMARKING 2>/dev/null || true

# تحديد أولوية عالية لعمليات HTTP Custom عبر UDP
iptables -t mangle -A UDPMARKING -p udp -j MARK --set-mark 10
iptables -t mangle -A UDPMARKING -p udp -j DSCP --set-dscp-class EF
iptables -t mangle -A OUTPUT -p udp -j UDPMARKING
iptables -t mangle -A POSTROUTING -p udp -m dscp --dscp-class EF -j DSCP --set-dscp-class EF

# تحسين تدفق الحزم لتقليل التأخير
iptables -A OUTPUT -p udp -j ACCEPT
iptables -A INPUT -p udp -j ACCEPT

# ======== إعداد موارد النظام ========
echo 131072 > /proc/sys/kernel/threads-max
echo 131072 > /proc/sys/vm/max_map_count
echo 131072 > /proc/sys/kernel/pid_max

# تحسين أداء الشبكة للاتصالات UDP
echo "net.ipv4.udp_l3mdev_accept=1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> /etc/sysctl.conf
echo "net.ipv4.route.gc_timeout=100" >> /etc/sysctl.conf

# تفعيل التغييرات
sysctl -p

# ======== إنشاء خدمة systemd لتطبيق التحسينات عند الإقلاع ========
cat > /etc/systemd/system/udp-custom-optimize.service <<EOF
[Unit]
Description=UDP Custom Advanced Optimization Service for Lower Ping
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'IFACE=\$(ip -o -4 route show to default | awk "{print \$5}"); \
tc qdisc del dev \$IFACE root 2>/dev/null || true; \
tc qdisc add dev \$IFACE root handle 1: htb default 10; \
tc class add dev \$IFACE parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit quantum 60000; \
tc class add dev \$IFACE parent 1:1 classid 1:10 htb rate 900mbit ceil 1000mbit prio 0 quantum 60000; \
tc class add dev \$IFACE parent 1:1 classid 1:20 htb rate 95mbit ceil 500mbit prio 1 quantum 60000; \
tc qdisc add dev \$IFACE parent 1:10 handle 10: fq_codel limit 10240 target 5ms interval 30ms flows 4096 quantum 1514 ecn; \
tc qdisc add dev \$IFACE parent 1:20 handle 20: fq_codel limit 10240 target 5ms interval 30ms flows 4096 quantum 1514 ecn; \
tc filter add dev \$IFACE parent 1: protocol ip prio 1 u32 match ip protocol 17 0xff flowid 1:10; \
tc filter add dev \$IFACE parent 1: protocol ip prio 1 handle 10 fw flowid 1:10; \
ip link set dev \$IFACE txqueuelen 16000; \
iptables -t mangle -N UDPMARKING 2>/dev/null || true; \
iptables -t mangle -F UDPMARKING; \
iptables -t mangle -D OUTPUT -p udp -j UDPMARKING 2>/dev/null || true; \
iptables -t mangle -A UDPMARKING -p udp -j MARK --set-mark 10; \
iptables -t mangle -A UDPMARKING -p udp -j DSCP --set-dscp-class EF; \
iptables -t mangle -A OUTPUT -p udp -j UDPMARKING; \
iptables -t mangle -A POSTROUTING -p udp -m dscp --dscp-class EF -j DSCP --set-dscp-class EF; \
iptables -A OUTPUT -p udp -j ACCEPT; \
iptables -A INPUT -p udp -j ACCEPT;'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom-optimize.service
systemctl start udp-custom-optimize.service

# إنشاء سكريبت لمراقبة وتحسين الاتصالات UDP بشكل مستمر
cat > /usr/local/bin/udp-monitor.sh <<EOF
#!/bin/bash

while true; do
  # إعادة تعيين قيم الشبكة المثلى كل ساعة لضمان استقرار الاتصال
  sysctl -w net.ipv4.udp_mem="131072 262144 67108864"
  sysctl -w net.core.rmem_max=67108864
  sysctl -w net.core.wmem_max=67108864
  sysctl -w net.ipv4.tcp_congestion_control=bbr
  
  # تنظيف ذاكرة التخزين المؤقت للشبكة
  echo 3 > /proc/sys/vm/drop_caches
  ip route flush cache
  
  # إعادة تنشيط جدولة الشبكة إذا كان هناك تأخير كبير
  PING=\$(ping -c 3 1.1.1.1 | grep "avg" | cut -d "/" -f 5)
  if (( \$(echo "\$PING > 150" | bc -l) )); then
    IFACE=\$(ip -o -4 route show to default | awk '{print \$5}')
    tc qdisc del dev \$IFACE root 2>/dev/null || true
    tc qdisc add dev \$IFACE root handle 1: htb default 10
    tc class add dev \$IFACE parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit quantum 60000
    tc class add dev \$IFACE parent 1:1 classid 1:10 htb rate 900mbit ceil 1000mbit prio 0 quantum 60000
    tc qdisc add dev \$IFACE parent 1:10 handle 10: fq_codel limit 10240 target 5ms interval 30ms flows 4096 quantum 1514 ecn
    tc filter add dev \$IFACE parent 1: protocol ip prio 1 u32 match ip protocol 17 0xff flowid 1:10
  fi
  
  sleep 3600
done
EOF

chmod +x /usr/local/bin/udp-monitor.sh

# إنشاء خدمة لتشغيل المراقب
cat > /etc/systemd/system/udp-monitor.service <<EOF
[Unit]
Description=UDP Connection Monitor and Optimizer
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/udp-monitor.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-monitor.service
systemctl start udp-monitor.service

echo "✅ تم تطبيق تحسينات متقدمة للحصول على ping منخفض واستقرار أفضل في الاتصال"
echo "🔄 تم تفعيل نظام مراقبة مستمر لضمان استقرار الاتصال وتقليل التقطعات"
echo "⚠️ يجب إعادة تشغيل النظام الآن لتفعيل كافة التعديلات: sudo reboot"

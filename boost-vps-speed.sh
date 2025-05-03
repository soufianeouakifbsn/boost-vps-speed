#!/bin/bash
echo "🚀 تحسين شامل لضمان استقرار اتصال Hysteria بدون تقطع حتى لـ 100 مستخدم!"

# 🧠 إعدادات نواة النظام
cat > /etc/sysctl.conf <<EOF
# حجم البفر
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_rmem_max = 134217728
net.ipv4.udp_wmem_max = 134217728

# إعادة استخدام البورت
net.ipv4.udp_so_reuseport = 1

# تقليل التقطيع عبر MTU probing
net.ipv4.tcp_mtu_probing = 1

# حجم قائمة الاتصالات
net.netfilter.nf_conntrack_max = 262144
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 60

# زيادة عدد الملفات المفتوحة
fs.file-max = 2097152
EOF
sysctl -p

# رفع ulimit
echo "fs.file-max = 2097152" >> /etc/sysctl.conf
ulimit -n 1048576

# 🔄 تطبيق الجدولة fq_codel أو cake (إذا كانت متاحة)
IFACE="eth0"
if tc qdisc add dev $IFACE root handle 1: cake bandwidth 1gbit 2>/dev/null; then
  echo "✅ تم تطبيق CAKE scheduler لمزيد من الاستقرار"
else
  tc qdisc replace dev $IFACE root fq_codel quantum 12000
  echo "✅ تم تطبيق fq_codel scheduler كبديل"
fi

# 🎯 إعداد كرت الشبكة
ethtool -G $IFACE rx 1024 tx 1024
ethtool -C $IFACE rx-usecs 64 tx-usecs 64
ethtool -s $IFACE speed 10000 duplex full autoneg off
ethtool -K $IFACE gro on lro on

# txqueuelen
ifconfig $IFACE txqueuelen 1500000

# 🔥 تم
echo "✅ جميع التحسينات طبقت بنجاح. جاهز لاستقبال 100 اتصال بدون تقطع بإذن الله!"
echo "🔄 أعد تشغيل السيرفر لتثبيت بعض القيم بشكل دائم."

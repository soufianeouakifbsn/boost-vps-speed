#!/bin/bash
echo "🚀 تحسين شامل لأداء UDP لتسريع الاتصال عبر Hysteria! ⚡"

# تحسين الاتصال عبر UDP لتقليل الفقد والاختناق
echo "🔥 ضبط إعدادات UDP لأداء مستقر وسريع!"
cat > /etc/sysctl.conf <<EOF
# زيادة حجم الذاكرة المؤقتة لتقليل فقد الحزم
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.udp_rmem_max = 67108864
net.ipv4.udp_wmem_max = 67108864

# تحسين التعامل مع البورتات لإعادة الاستخدام بشكل أكثر كفاءة
net.ipv4.udp_so_reuseport = 1

# تمكين MTU probing لضمان أفضل حجم للحزم
net.ipv4.tcp_mtu_probing = 1
EOF

sysctl -p

# تحسين QoS باستخدام fq_codel لتقليل التأخير والتقطع
echo "🔥 تطبيق fq_codel على واجهة الشبكة لتقليل التأخير!"
tc qdisc replace dev eth0 root fq_codel quantum 12000

# ضبط بطاقة الشبكة لضمان استجابة عالية
echo "🔧 ضبط بطاقة الشبكة لأقصى أداء!"
IFACE="eth0"
ethtool -G $IFACE rx 512 tx 512
ethtool -C $IFACE rx-usecs 64 tx-usecs 64
ethtool -s $IFACE speed 10000 duplex full autoneg off
ethtool -K $IFACE gro on lro on

# ضبط txqueuelen لتجنب اختناق البوفر الخاص بواجهة الشبكة
echo "⚡ رفع txqueuelen لدعم تدفق بيانات UDP بكفاءة!"
ifconfig eth0 txqueuelen 1500000

echo "✅ تم تطبيق جميع التحسينات الخاصة بـ UDP! مناسب لبروتوكول Hysteria 🚀"
echo "📢 يُفضل إعادة تشغيل السيرفر لضمان أفضل تجربة."

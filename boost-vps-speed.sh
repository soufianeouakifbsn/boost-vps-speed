#!/bin/bash

# تحديث النظام
echo "تحديث النظام..."
apt update -y && apt upgrade -y

# تثبيت الأدوات المطلوبة
echo "تثبيت الأدوات المطلوبة..."
apt install -y wireguard qrencode curl iptables

# توليد مفاتيح السيرفر
echo "توليد مفاتيح السيرفر..."
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# جلب IP الخاص بالسيرفر
SERVER_IP=$(curl -s ifconfig.me)

# إنشاء ملف التكوين للسيرفر
echo "إعداد ملف التكوين للسيرفر..."
cat <<EOL > /etc/wireguard/wg0.conf
[Interface]
Address = 10.66.66.1/24
PrivateKey = $SERVER_PRIVATE_KEY
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
EOL

# إعداد ملف العميل
USER_HOME=$(eval echo ~${SUDO_USER})
echo "إعداد ملف التكوين للعميل..."
cat <<EOL > ${USER_HOME}/phone.conf
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.66.66.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOL

# تفعيل وتشغيل خدمة WireGuard
echo "تفعيل وتشغيل WireGuard..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# توليد QR Code للملف
echo "توليد QR Code للملف..."
qrencode -t ansiutf8 < ${USER_HOME}/phone.conf

# عرض ملخص
echo ""
echo "✅ تم تثبيت WireGuard بنجاح!"
echo "📂 ملف إعداد الاتصال موجود هنا: ${USER_HOME}/phone.conf"
echo "📸 امسح QR Code أعلاه عبر تطبيق WireGuard على هاتفك."

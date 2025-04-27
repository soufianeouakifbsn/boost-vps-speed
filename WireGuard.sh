#!/bin/bash

# تحديث النظام
apt update -y
apt upgrade -y

# تثبيت WireGuard والبرامج اللازمة
apt install wireguard qrencode curl -y

# تحديد اسم المستخدم الحالي ومساره
USER_HOME=$(eval echo ~${SUDO_USER})

# إنشاء مجلد WireGuard إذا لم يكن موجود
mkdir -p /etc/wireguard

# توليد المفاتيح
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# جلب IP الخاص بالسيرفر
SERVER_IP=$(curl -s ifconfig.me)

# إعداد ملف السيرفر
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
AllowedIPs = 10.66.66.2/32
EOL

# إعداد ملف العميل (هاتفك)
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

# تفعيل الخدمة
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# توليد QR Code وحفظه كصورة
qrencode -t png < ${USER_HOME}/phone.conf -o ${USER_HOME}/phone_qr.png

# عرض المسار إلى الصورة
echo ""
echo "✅ تم تثبيت WireGuard بنجاح!"
echo "📂 ملف إعداد الاتصال موجود هنا: ${USER_HOME}/phone.conf"
echo "📸 تم حفظ QR Code في الملف: ${USER_HOME}/phone_qr.png"
echo "📲 امسح QR Code عبر تطبيق WireGuard على هاتفك."

#!/bin/bash

# تحديث النظام
apt update -y
apt upgrade -y

# تثبيت WireGuard والبرامج اللازمة
apt install wireguard qrencode curl -y

# تحديد اسم المستخدم الحالي ومساره
USER_HOME=$(eval echo ~$USER)

# إنشاء مجلد WireGuard إذا لم يكن موجود
mkdir -p /etc/wireguard

# إدخال بيانات السيرفر يدوياً
echo "أدخل المفتاح الخاص بالسيرفر:"
read SERVER_PRIVATE_KEY
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# إدخال بيانات العميل يدوياً
echo "أدخل المفتاح الخاص بالعميل:"
read CLIENT_PRIVATE_KEY
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# إدخال IP السيرفر يدوياً
echo "أدخل عنوان الـ IP الخاص بالسيرفر (مثال: 192.168.1.1):"
read SERVER_IP

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
AllowedIPs = 0.0.0.0/0
EOL

# إعداد ملف العميل (هاتفك)
cat <<EOL > ${USER_HOME}/phone.conf
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.66.66.2/24  # هذا هو العنوان الذي سيتحصل عليه العميل
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

# توليد QR Code وعرضه في الطرفية باستخدام الترميز utf8
qrencode -t utf8 < ${USER_HOME}/phone.conf

# عرض ملخص
echo ""
echo "✅ تم تثبيت WireGuard بنجاح!"
echo "📂 ملف إعداد الاتصال موجود هنا: ${USER_HOME}/phone.conf"
echo "📸 امسح QR Code أعلاه عبر تطبيق WireGuard على هاتفك."

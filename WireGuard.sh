#!/bin/bash

# تأكد من أنك تقوم بتشغيل السكربت كـ root أو مستخدم لديه صلاحيات sudo
if [[ $EUID -ne 0 ]]; then
  echo "يرجى تشغيل هذا السكربت كـ root أو باستخدام sudo"
  exit 1
fi

# تحديث النظام
echo "تحديث النظام..."
apt update -y && apt upgrade -y

# تثبيت الأدوات المطلوبة
echo "تثبيت الأدوات المطلوبة..."
apt install -y wireguard qrencode curl iptables -y

# تحديد اسم واجهة WireGuard
INTERFACE="wg0"
SERVER_ADDRESS="10.66.66.1/24"
LISTEN_PORT="51820"
DNS_SERVER="1.1.1.1"

# توليد مفاتيح السيرفر
echo "توليد مفاتيح السيرفر..."
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# توليد مفاتيح العميل
echo "توليد مفاتيح العميل..."
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
CLIENT_ADDRESS="10.66.66.2/24"

# جلب IP الخاص بالسيرفر
echo "جلب IP الخاص بالسيرفر..."
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
  echo "فشل في جلب IP الخاص بالسيرفر. يرجى التأكد من اتصالك بالإنترنت."
  exit 1
fi

# إنشاء ملف التكوين للسيرفر
echo "إعداد ملف التكوين للسيرفر: /etc/wireguard/${INTERFACE}.conf"
cat <<EOL > /etc/wireguard/${INTERFACE}.conf
[Interface]
Address = ${SERVER_ADDRESS}
PrivateKey = ${SERVER_PRIVATE_KEY}
ListenPort = ${LISTEN_PORT}
PostUp = iptables -A FORWARD -i ${INTERFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i ${INTERFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
SaveConfig = true

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_ADDRESS}
EOL

# إعداد ملف العميل
USER_HOME=$(eval echo ~${SUDO_USER})
CLIENT_CONFIG_FILE="${USER_HOME}/client_${INTERFACE}.conf"
echo "إعداد ملف التكوين للعميل: ${CLIENT_CONFIG_FILE}"
cat <<EOL > ${CLIENT_CONFIG_FILE}
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_ADDRESS}
DNS = ${DNS_SERVER}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_IP}:${LISTEN_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOL

# تفعيل وتشغيل خدمة WireGuard
echo "تفعيل وتشغيل خدمة WireGuard..."
systemctl enable wg-quick@${INTERFACE}
systemctl start wg-quick@${INTERFACE}

# توليد QR Code للملف
echo "توليد QR Code لملف العميل..."
if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ansiutf8 < "${CLIENT_CONFIG_FILE}"
else
  echo "الأداة qrencode غير مثبتة. لا يمكن توليد رمز QR."
  echo "يمكنك تثبيتها باستخدام الأمر: sudo apt install qrencode"
fi

# عرض ملخص
echo ""
echo "✅ تم تثبيت وتكوين WireGuard بنجاح!"
echo "📂 ملف إعداد العميل موجود هنا: ${CLIENT_CONFIG_FILE}"
if command -v qrencode >/dev/null 2>&1; then
  echo "📸 امسح رمز QR أعلاه عبر تطبيق WireGuard على هاتفك لإضافة النفق."
else
  echo "🔑 يمكنك إضافة نفق WireGuard على هاتفك يدويًا باستخدام المعلومات الموجودة في ملف التكوين."
fi
echo "⚠️ تأكد من أن جدار الحماية (firewall) على خادمك يسمح باتصالات UDP على المنفذ ${LISTEN_PORT}."

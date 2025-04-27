#!/bin/bash

# تحديث النظام
sudo apt update -y
sudo apt upgrade -y

# تثبيت WireGuard
sudo apt install wireguard -y

# توليد مفاتيح WireGuard
wg genkey | tee privatekey | wg pubkey > publickey
wg genkey | tee client_privatekey | wg pubkey > client_publickey

# تحديد عنوان IP للـ VPS
VPS_IP=$(curl -s ifconfig.me)

# إعداد ملف السيرفر WireGuard
cat <<EOL > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat privatekey)
Address = 10.66.66.1/24
ListenPort = 51820
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $(cat client_publickey)
AllowedIPs = 10.66.66.2/32
EOL

# تفعيل WireGuard
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0

# إعداد اتصال العميل
cat <<EOL > /home/ubuntu/phone.conf
[Interface]
PrivateKey = $(cat client_privatekey)
Address = 10.66.66.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat publickey)
Endpoint = $VPS_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOL

# توليد QR Code للاتصال عبر الهاتف
sudo apt install qrencode -y
qrencode -t ansiutf8 < /home/ubuntu/phone.conf

echo "WireGuard تم تثبيته بنجاح! قم بفحص QR Code أعلى الشاشة لمسح الكود في تطبيق WireGuard على هاتفك."

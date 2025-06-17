#!/bin/bash

# ⚙️ إيقاف أي نسخة سابقة من short-video-maker
echo "🛑 إيقاف أي حاوية سابقة من short-video-maker..."
sudo docker stop short-video-maker &> /dev/null
sudo docker rm short-video-maker &> /dev/null

# 🐳 التأكد من أن Docker مثبت
if ! command -v docker &> /dev/null; then
  echo "🛠️ تثبيت Docker..."
  sudo apt update
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  sudo apt update
  sudo apt install -y docker-ce
else
  echo "✅ Docker مثبت مسبقًا."
fi

# 🧰 تثبيت ngrok و jq
echo "📦 تثبيت ngrok و jq..."
wget -O ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar -xvzf ngrok.tgz -C /usr/local/bin
sudo apt install -y jq

# 🔐 إعداد بيانات ngrok و PEXELS
NGROK_AUTH_TOKEN="ادخل هنا التوكن الخاص بك"
NGROK_DOMAIN="talented-fleet-monkfish.ngrok-free.app"
PEXELS_API_KEY="FDrZIasw3qXF6eOCc0dafpZ9cJnN2FfAWi3xEn1mcHy9lqmLqpuIebwC"

# 🔧 تهيئة ngrok
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
ngrok http --domain="$NGROK_DOMAIN" 3123 > /dev/null &

# 🕐 الانتظار حتى يبدأ ngrok
echo "🕐 الانتظار حتى يبدأ ngrok..."
sleep 8

# 🌍 الحصول على الرابط من ngrok
export EXTERNAL_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
echo "🌐 رابط ngrok هو: $EXTERNAL_URL"

# 🚀 تشغيل الحاوية
echo "🚀 تشغيل حاوية short-video-maker..."
sudo docker run -d --name short-video-maker \
  --restart unless-stopped \
  -p 3123:3123 \
  -e PEXELS_API_KEY=$PEXELS_API_KEY \
  gyoridavid/short-video-maker:latest-tiny

echo "✅ تم تشغيل short-video-maker بنجاح!"
echo "🌐 يمكنك الوصول إليه من خلال: $EXTERNAL_URL"

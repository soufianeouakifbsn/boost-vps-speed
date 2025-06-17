#!/bin/bash

echo "🧹 إزالة كل ما يتعلق بـ short-video-maker..."

# 1. حذف الحاوية إذا كانت موجودة
if [ "$(sudo docker ps -a -q -f name=short-video-maker)" ]; then
  echo "🛑 إيقاف وحذف الحاوية..."
  sudo docker stop short-video-maker
  sudo docker rm short-video-maker
fi

# 2. حذف الصورة (image) من النظام
if sudo docker images | grep -q "gyoridavid/short-video-maker"; then
  echo "🗑️ حذف صورة short-video-maker..."
  sudo docker rmi gyoridavid/short-video-maker:latest-tiny
fi

# 3. حذف أي ملفات إعداد أو مجلدات قديمة (اختياري إذا تم حفظها)
# sudo rm -rf /path/to/old/config-or-volume-data (في حال كنت تستخدم حجم دائم - volume)

echo "✅ تم الحذف بالكامل!"

echo "🚀 بدء التثبيت من جديد..."

# التأكد من Docker
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

# تثبيت ngrok و jq
echo "📦 تثبيت ngrok و jq..."
wget -O ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar -xvzf ngrok.tgz -C /usr/local/bin
sudo apt install -y jq

# إعداد البيانات
NGROK_AUTH_TOKEN="ضع_توكن_ngrok_هنا"
NGROK_DOMAIN="talented-fleet-monkfish.ngrok-free.app"
PEXELS_API_KEY="FDrZIasw3qXF6eOCc0dafpZ9cJnN2FfAWi3xEn1mcHy9lqmLqpuIebwC"

# إعداد ngrok
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
ngrok http --domain="$NGROK_DOMAIN" 3123 > /dev/null &

# انتظار ngrok
sleep 8
EXTERNAL_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

# تشغيل الحاوية
echo "🎬 تشغيل short-video-maker..."
sudo docker run -d --name short-video-maker \
  --restart unless-stopped \
  -p 3123:3123 \
  -e PEXELS_API_KEY=$PEXELS_API_KEY \
  gyoridavid/short-video-maker:latest-tiny

echo "✅ تم تثبيت وتشغيل short-video-maker من الصفر!"
echo "🌍 الوصول عبر: $EXTERNAL_URL"

#!/bin/bash

# التأكد من تثبيت Docker
echo "🚀 التأكد من أن Docker مثبت..."
if ! command -v docker &> /dev/null; then
  echo "🛠️  تثبيت Docker..."
  sudo apt update
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  sudo apt update
  sudo apt install -y docker-ce
  echo "✅ تم تثبيت Docker!"
else
  echo "✅ Docker مثبت مسبقًا."
fi

# التحقق من تشغيل Docker
if ! sudo systemctl is-active --quiet docker; then
  echo "🔄 بدء خدمة Docker..."
  sudo systemctl start docker
fi

# تشغيل حاوية short-video-maker
echo "🎬 تشغيل حاوية short-video-maker..."

PEXELS_API_KEY="FDrZIasw3qXF6eOCc0dafpZ9cJnN2FfAWi3xEn1mcHy9lqmLqpuIebwC"

sudo docker run -d --name short-video-maker \
  --restart unless-stopped \
  -p 3123:3123 \
  -e PEXELS_API_KEY=$PEXELS_API_KEY \
  gyoridavid/short-video-maker:latest-tiny

echo "✅ تم تشغيل short-video-maker بنجاح!"
echo "🌐 افتح المتصفح وادخل إلى: http://$(hostname -I | awk '{print $1}'):3123"

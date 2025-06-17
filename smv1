#!/bin/bash

# تثبيت Docker إذا لم يكن مثبتًا
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

# تشغيل الحاوية الخاصة بمولد الفيديوهات
echo "🎬 تشغيل حاوية short-video-maker..."

# أدخل مفتاح PEXELS الخاص بك هنا (بدله إذا كان مختلفًا)
PEXELS_API_KEY="FDrZIasw3qXF6eOCc0dafpZ9cJnN2FfAWi3xEn1mcHy9lqmLqpuIebwC"

sudo docker run -d --name short-video-maker \
  --restart unless-stopped \
  -p 3123:3123 \
  -e PEXELS_API_KEY=$PEXELS_API_KEY \
  gyoridavid/short-video-maker:latest-tiny

echo "✅ تم تشغيل short-video-maker بنجاح!"
echo "🌐 يمكنك الوصول إليه عبر: http://<IP-ADDRESS>:3123"

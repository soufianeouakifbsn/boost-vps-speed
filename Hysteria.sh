#!/bin/bash

# تثبيت curl لو مش موجود
apt update -y
apt install -y curl

# تثبيت Hysteria
bash <(curl -fsSL https://get.hy2.sh/)

# إنشاء ملف الإعداد
cat > /etc/hysteria/config.yaml << EOF
listen: :5678
auth:
  type: password
  password: lwalida
up_mbps: 100
down_mbps: 100
obfs:
  type: salamander
  salamander:
    password: lwalida
EOF

# إعادة تشغيل الخدمة
systemctl restart hysteria-server.service
systemctl enable hysteria-server.service

echo "✅ Hysteria Server is installed and running!"

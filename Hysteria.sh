#!/bin/bash

echo "🔵 بدء تحديث/إعادة تثبيت Hysteria Server..."

# تحديث النظام وتثبيت curl
apt update -y
apt install -y curl

# إيقاف وحذف Hysteria القديم إن وجد
systemctl stop hysteria-server.service 2>/dev/null
systemctl disable hysteria-server.service 2>/dev/null
rm -rf /etc/hysteria
rm -f /etc/systemd/system/hysteria-server.service
rm -f /usr/local/bin/hysteria

echo "✅ تم حذف Hysteria القديم (إن وجد)."

# تنزيل وتثبيت آخر نسخة من Hysteria
bash <(curl -fsSL https://get.hy2.sh/)

# إنشاء مجلد الإعداد
mkdir -p /etc/hysteria

# إنشاء ملف إعداد جديد
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

# إعادة تحميل الخدمات وإعادة تشغيل Hysteria
systemctl daemon-reload
systemctl restart hysteria-server.service
systemctl enable hysteria-server.service

echo "🎯 Hysteria Server تم تثبيته وتحديثه بنجاح!"
systemctl status hysteria-server.service --no-pager

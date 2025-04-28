#!/bin/bash

# تحميل السكربت مباشرة من GitHub وتنفيذه
echo "تحميل السكربت من GitHub..."

# تأكد من أنك تعمل كـ root أو استخدم sudo
echo "جارٍ تحميل ملفات التكوين..."

# إعداد ملف تكوين الخادم
echo "إنشاء ملف التكوين للخادم..."
cat << EOF > /etc/hysteria/config.yaml
listen: :443 # استماع على المنفذ 443

# استخدام شهادة موقعة ذاتيًا
# tls:
#   cert: /etc/hysteria/server.crt
#   key: /etc/hysteria/server.key

auth:
  type: password
  password: 123456 # كلمة المرور للمصادقة
  
masquerade:
  type: proxy
  proxy:
    url: https://bing.com # عنوان التمويه
    rewriteHost: true
EOF

# إعداد ملف تكوين العميل
echo "إنشاء ملف التكوين للعميل..."
cat << EOF > /etc/hysteria/client_config.yaml
server: ip:443
auth: 123456

bandwidth:
  up: 20 mbps
  down: 100 mbps
  
tls:
  sni: a.com
  insecure: false # استخدم true إذا كنت تستخدم شهادة موقعة ذاتيًا

socks5:
  listen: 127.0.0.1:1080
http:
  listen: 127.0.0.1:8080
EOF

# إعداد ملف تكوين sing-box
echo "إنشاء ملف التكوين لـ sing-box..."
cat << EOF > /etc/sing-box/config.json
{
  "dns": {
    "servers": [
      {
        "tag": "cf",
        "address": "https://1.1.1.1/dns-query"
      },
      {
        "tag": "local",
        "address": "223.5.5.5",
        "detour": "direct"
      },
      {
        "tag": "block",
        "address": "rcode://success"
      }
    ],
    "rules": [
      {
        "geosite": "category-ads-all",
        "server": "block",
        "disable_cache": true
      },
      {
        "outbound": "any",
        "server": "local"
      },
      {
        "geosite": "cn",
        "server": "local"
      }
    ],
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "tun",
      "inet4_address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": false,
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "hysteria2",
      "tag": "proxy",
      "server": "ip",
      "server_port": 443,
      "up_mbps": 20,
      "down_mbps": 100,
      "password": "123456",
      "tls": {
        "enabled": true,
        "server_name": "a.com",
        "insecure": false
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "geosite": "cn",
        "geoip": [
          "private",
          "cn"
        ],
        "outbound": "direct"
      },
      {
        "geosite": "category-ads-all",
        "outbound": "block"
      }
    ],
    "auto_detect_interface": true
  }
}
EOF

echo "تم إنشاء ملفات التكوين بنجاح."

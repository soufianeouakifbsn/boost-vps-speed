cat << EOF > /etc/hysteria/config.yaml
listen: :443 #监听端口

#使用CA证书
#acme:
#  domains:
#    - a.com #你的域名，需要先解析到服务器ip
#  email: test@sharklasers.com

#使用自签证书
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: 123456 #设置认证密码
  
masquerade:
  type: proxy
  proxy:
    url: https://bing.com #伪装网址
    rewriteHost: true
EOF

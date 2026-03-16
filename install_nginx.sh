#!/bin/bash

echo "🔄 Instalando Nginx..."
sudo apt update
sudo apt install nginx -y

echo "✅ Nginx instalado"

echo "🔄 Configurando Nginx para TickPro..."
sudo tee /etc/nginx/sites-available/tickpro > /dev/null << 'EOF'
server {
    listen 80;
    server_name localhost 127.0.0.1;

    access_log /home/christian/tickets/logs/nginx_access.log;
    error_log /home/christian/tickets/logs/nginx_error.log;

    location /static/ {
        alias /home/christian/tickets/staticfiles/;
    }

    location /media/ {
        alias /home/christian/tickets/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "🔄 Creando enlaces..."
sudo ln -sf /etc/nginx/sites-available/tickpro /etc/nginx/sites-enabled/

echo "🔄 Eliminando configuración por defecto..."
sudo rm -f /etc/nginx/sites-enabled/default

echo "🔄 Verificando configuración..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración válida"
    echo "🔄 Reiniciando Nginx..."
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    echo "✅ Nginx configurado y corriendo"
else
    echo "❌ Error en configuración de Nginx"
    exit 1
fi

echo ""
echo "=========================================="
echo "🌐 Accede a TickPro en:"
echo "   http://localhost"
echo "   http://127.0.0.1"
echo "=========================================="
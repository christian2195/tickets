#!/bin/bash

echo "🔧 Configurando Nginx para TickPro..."

# Eliminar configuración por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# Crear directorio de logs si no existe
mkdir -p /home/christian/tickets/logs

# Crear configuración de Nginx
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

# Activar configuración
sudo ln -sf /etc/nginx/sites-available/tickpro /etc/nginx/sites-enabled/

# Verificar configuración
echo "🔍 Verificando configuración..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuración válida"
    
    # Reiniciar Nginx
    echo "🔄 Reiniciando Nginx..."
    sudo systemctl restart nginx
    
    # Verificar que Gunicorn está corriendo
    if ! pgrep -f gunicorn > /dev/null; then
        echo "⚠️  Gunicorn no está corriendo. Iniciándolo..."
        cd /home/christian/tickets
        source venv/bin/activate
        nohup gunicorn --bind 127.0.0.1:8000 \
            --workers 3 \
            --timeout 120 \
            --access-logfile logs/gunicorn_access.log \
            --error-logfile logs/gunicorn_error.log \
            --daemon \
            tikects_proyecto.wsgi:application
        echo "✅ Gunicorn iniciado"
    else
        echo "✅ Gunicorn ya está corriendo"
    fi
    
    echo ""
    echo "=========================================="
    echo "🎉 ¡TickPro está configurado!"
    echo "=========================================="
    echo "🌐 Accede a tu aplicación en:"
    echo "   http://localhost"
    echo "   http://127.0.0.1"
    echo ""
    echo "📝 Para ver logs:"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo "   tail -f logs/gunicorn_error.log"
    echo "=========================================="
else
    echo "❌ Error en la configuración"
    exit 1
fi
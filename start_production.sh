#!/bin/bash

echo "🚀 Iniciando TickPro en producción..."

# Crear directorios necesarios
mkdir -p /home/christian/tickets/logs
mkdir -p /home/christian/tickets/media

# Activar entorno virtual
source /home/christian/tickets/venv/bin/activate

# Recolectar archivos estáticos (por si acaso)
python manage.py collectstatic --noinput

# Matar procesos anteriores
pkill gunicorn 2>/dev/null
sudo systemctl stop nginx 2>/dev/null

# Iniciar Gunicorn
echo "📡 Iniciando Gunicorn..."
cd /home/christian/tickets
nohup gunicorn --bind 127.0.0.1:8000 \
    --workers 3 \
    --timeout 120 \
    --access-logfile logs/gunicorn_access.log \
    --error-logfile logs/gunicorn_error.log \
    --daemon \
    tikects_proyecto.wsgi:application

# Esperar un momento
sleep 2

# Verificar que Gunicorn está corriendo
if pgrep -f gunicorn > /dev/null; then
    echo "✅ Gunicorn iniciado correctamente"
else
    echo "❌ Error iniciando Gunicorn"
    cat logs/gunicorn_error.log
    exit 1
fi

# Iniciar Nginx
echo "🌐 Iniciando Nginx..."
sudo systemctl start nginx
sudo systemctl status nginx --no-pager | grep "Active"

echo ""
echo "=========================================="
echo "✅ SISTEMA INICIADO CORRECTAMENTE"
echo "=========================================="
echo "🌐 Accede a TickPro:"
echo "   http://localhost"
echo "   http://127.0.0.1"
echo ""
echo "📝 Ver logs:"
echo "   tail -f logs/gunicorn_error.log"
echo "   tail -f logs/nginx_error.log"
echo "=========================================="
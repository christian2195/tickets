#!/bin/bash

# Script rápido para reiniciar la aplicación
PROJECT_DIR="/home/christian/tickets"
cd "$PROJECT_DIR" || exit

source venv/bin/activate

echo "🔄 Reiniciando aplicación..."

# Matar procesos anteriores
pkill -f gunicorn 2>/dev/null

# Iniciar Gunicorn
nohup gunicorn --bind 0.0.0.0:8000 \
    --workers 3 \
    --timeout 120 \
    --access-logfile logs/access.log \
    --error-logfile logs/error.log \
    tikects_proyecto.wsgi:application > /dev/null 2>&1 &

echo "✅ Aplicación reiniciada en puerto 8000"
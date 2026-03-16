#!/bin/bash

echo "🛑 Deteniendo TickPro..."

# Detener Gunicorn
pkill gunicorn 2>/dev/null
echo "✅ Gunicorn detenido"

# Detener Nginx
sudo systemctl stop nginx
echo "✅ Nginx detenido"

echo "🎯 Sistema detenido"
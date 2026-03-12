#!/bin/bash

echo "🔄 Configurando el sistema de tickets..."

# Activar entorno virtual
source venv/bin/activate

# 1. Recrear la base de datos desde cero
echo "🗑️  Eliminando base de datos existente..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS tickets_db;"
sudo -u postgres psql -c "CREATE DATABASE tickets_db OWNER tickets_user;"

# 2. Dar permisos completos
echo "🔑 Configurando permisos..."
sudo -u postgres psql -d tickets_db -c "GRANT ALL ON SCHEMA public TO tickets_user;"
sudo -u postgres psql -d tickets_db -c "ALTER SCHEMA public OWNER TO tickets_user;"

# 3. Eliminar migraciones antiguas (opcional, si quieres empezar fresco)
echo "🧹 Limpiando migraciones antiguas..."
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete

# 4. Crear nuevas migraciones
echo "📦 Creando migraciones..."
python manage.py makemigrations tickets
python manage.py makemigrations reportes

# 5. Aplicar todas las migraciones
echo "🚀 Aplicando migraciones..."
python manage.py migrate

# 6. Crear superusuario
echo "👤 Creando superusuario..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123')" | python manage.py shell

# 7. Verificar la instalación
echo "✅ Verificando instalación..."
python manage.py check

echo ""
echo "===================================="
echo "✅ CONFIGURACIÓN COMPLETA"
echo "===================================="
echo "🌐 Para iniciar el servidor:"
echo "   python manage.py runserver 0.0.0.0:8000"
echo ""
echo "🔑 Credenciales de acceso:"
echo "   Usuario: admin"
echo "   Contraseña: 1234"
echo "===================================="
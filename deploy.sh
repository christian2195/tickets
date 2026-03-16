#!/bin/bash

# Script de despliegue automático para TickPro
# Autor: Sistema TickPro
# Fecha: 2024

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_NAME="tickpro"
PROJECT_DIR="/home/christian/tickets"
VENV_DIR="$PROJECT_DIR/venv"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_FILE="$PROJECT_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

# Función para logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Inicio del script
clear
echo "========================================="
echo "   DESPLIEGUE DE TICKPRO - PRODUCCIÓN   "
echo "========================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "$PROJECT_DIR" ]; then
    error "Directorio del proyecto no encontrado: $PROJECT_DIR"
fi

cd "$PROJECT_DIR" || error "No se puede acceder al directorio del proyecto"

log "Iniciando despliegue en producción..."

# 1. Verificar entorno virtual
info "Verificando entorno virtual..."
if [ ! -d "$VENV_DIR" ]; then
    warning "Entorno virtual no encontrado. Creando..."
    python3 -m venv venv || error "No se pudo crear el entorno virtual"
    log "✅ Entorno virtual creado"
else
    log "✅ Entorno virtual encontrado"
fi

# 2. Activar entorno virtual
info "Activando entorno virtual..."
source "$VENV_DIR/bin/activate" || error "No se pudo activar el entorno virtual"
log "✅ Entorno virtual activado"

# 3. Actualizar pip
info "Actualizando pip..."
pip install --upgrade pip >> "$LOG_FILE" 2>&1 || warning "No se pudo actualizar pip"
log "✅ Pip actualizado"

# 4. Instalar/actualizar dependencias
info "Instalando dependencias..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || error "Error instalando dependencias"
    log "✅ Dependencias instaladas"
else
    error "Archivo requirements.txt no encontrado"
fi

# 5. Verificar archivo .env
info "Verificando variables de entorno..."
if [ ! -f ".env" ]; then
    warning "Archivo .env no encontrado. Creando desde ejemplo..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Archivo .env creado. Por favor, edítalo con tus configuraciones:${NC}"
        echo "   nano .env"
        exit 1
    else
        error "No se encuentra .env.example"
    fi
else
    log "✅ Archivo .env encontrado"
fi

# 6. Backup de la base de datos
info "Creando backup de la base de datos..."
BACKUP_FILE="$BACKUP_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sqlite3"
if [ -f "db.sqlite3" ]; then
    cp db.sqlite3 "$BACKUP_FILE" >> "$LOG_FILE" 2>&1 || warning "No se pudo crear el backup"
    log "✅ Backup creado: $BACKUP_FILE"
    
    # Mantener solo los últimos 5 backups
    ls -t "$BACKUP_DIR"/db_backup_*.sqlite3 2>/dev/null | tail -n +6 | xargs -r rm
    log "✅ Backups antiguos eliminados"
else
    warning "No se encontró base de datos para backup"
fi

# 7. Aplicar migraciones
info "Aplicando migraciones..."
python manage.py makemigrations >> "$LOG_FILE" 2>&1 || warning "No hay nuevas migraciones"
python manage.py migrate >> "$LOG_FILE" 2>&1 || error "Error aplicando migraciones"
log "✅ Migraciones aplicadas"

# 8. Recolectar archivos estáticos
info "Recolectando archivos estáticos..."
python manage.py collectstatic --noinput >> "$LOG_FILE" 2>&1 || error "Error recolectando estáticos"
log "✅ Archivos estáticos recolectados"

# 9. Verificar superusuario
info "Verificando superusuario..."
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(is_superuser=True).exists():
    print('⚠️  No hay superusuario. Crea uno con: python manage.py createsuperuser')
" | tee -a "$LOG_FILE"

# 10. Verificar configuración de producción
info "Verificando configuración de producción..."
python manage.py check --deploy >> "$LOG_FILE" 2>&1
log "✅ Verificación completada"

# 11. Probar importación de módulos
info "Probando importación de módulos..."
python manage.py shell -c "
import openpyxl
import pandas
import reportlab
print('✅ Módulos OK')
" >> "$LOG_FILE" 2>&1 || warning "Problemas con algunos módulos"
log "✅ Módulos verificados"

# 12. Configurar permisos
info "Configurando permisos..."
chmod -R 755 "$PROJECT_DIR" >> "$LOG_FILE" 2>&1
chmod -R 664 "$PROJECT_DIR/db.sqlite3" 2>/dev/null
chmod -R 775 "$PROJECT_DIR/media" 2>/dev/null
chmod -R 775 "$PROJECT_DIR/staticfiles" 2>/dev/null
log "✅ Permisos configurados"

# 13. Verificar Gunicorn
info "Verificando Gunicorn..."
if command -v gunicorn &> /dev/null; then
    log "✅ Gunicorn instalado"
else
    warning "Gunicorn no instalado. Instalando..."
    pip install gunicorn >> "$LOG_FILE" 2>&1
fi

# 14. Verificar archivo de servicio systemd (opcional)
if [ -f "/etc/systemd/system/$PROJECT_NAME.service" ]; then
    info "Recargando servicio systemd..."
    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
    sudo systemctl restart "$PROJECT_NAME" >> "$LOG_FILE" 2>&1
    sudo systemctl status "$PROJECT_NAME" --no-pager >> "$LOG_FILE" 2>&1
    log "✅ Servicio reiniciado"
fi

# 15. Limpiar archivos temporales
info "Limpiando archivos temporales..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null
log "✅ Archivos temporales eliminados"

# 16. Crear archivo de versión
VERSION_FILE="$PROJECT_DIR/version.txt"
echo "Versión: $(date +%Y%m%d_%H%M%S)" > "$VERSION_FILE"
echo "Desplegado: $(date)" >> "$VERSION_FILE"
echo "Usuario: $(whoami)" >> "$VERSION_FILE"
log "✅ Archivo de versión creado"

# Resumen final
echo ""
echo "========================================="
echo "         RESUMEN DEL DESPLIEGUE         "
echo "========================================="
echo ""
echo -e "${GREEN}✅ Proyecto: $PROJECT_NAME${NC}"
echo -e "${GREEN}✅ Directorio: $PROJECT_DIR${NC}"
echo -e "${GREEN}✅ Log file: $LOG_FILE${NC}"
echo -e "${GREEN}✅ Backup: $BACKUP_FILE${NC}"
echo ""

# Mostrar advertencias si las hay
if [ -f "$LOG_FILE" ] && grep -i "warning" "$LOG_FILE" > /dev/null; then
    echo -e "${YELLOW}⚠️  Se encontraron advertencias. Revisa el log:${NC}"
    grep -i "warning" "$LOG_FILE" | tail -5
    echo ""
fi

# Próximos pasos
echo "========================================="
echo "           PRÓXIMOS PASOS               "
echo "========================================="
echo ""
echo "1. Para iniciar el servidor de prueba:"
echo "   python manage.py runserver --insecure"
echo ""
echo "2. Para iniciar con Gunicorn:"
echo "   gunicorn --bind 0.0.0.0:8000 tikects_proyecto.wsgi:application"
echo ""
echo "3. Verificar logs:"
echo "   tail -f $LOG_FILE"
echo ""
echo "4. Crear superusuario (si es necesario):"
echo "   python manage.py createsuperuser"
echo ""
echo "5. Configurar HTTPS con Let's Encrypt:"
echo "   sudo certbot --nginx -d tudominio.com"
echo ""

log "🎉 Despliegue completado exitosamente!"
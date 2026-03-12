// Variable global para la URL de notificaciones (se define en base.html)
let notificationApiUrl = window.notificationApiUrl || '/path/to/your/notification/api/';

// Función para agregar la animación a la campana
function animateBell() {
    const bell = document.querySelector('.notification-bell');
    if (bell) {
        bell.classList.add('animated', 'has-notification');
        setTimeout(() => {
            bell.classList.remove('animated');
        }, 1000);
    }
}

// Función para actualizar el contenido del menú de notificaciones
function updateNotifications(notifications) {
    const dropdownMenu = document.querySelector('#navbarDropdown + .dropdown-menu');
    const badge = document.querySelector('.notification-bell .badge');
    
    if (!dropdownMenu) return;
    
    // Actualizar contador
    if (badge) {
        badge.textContent = notifications.length > 0 ? '!' : '';
        badge.style.display = notifications.length > 0 ? 'inline' : 'none';
    }
    
    dropdownMenu.innerHTML = '';
    
    if (notifications.length === 0) {
        dropdownMenu.innerHTML = '<li class="dropdown-item text-muted">No hay notificaciones nuevas</li>';
        return;
    }
    
    notifications.forEach(notification => {
        const notificationItem = document.createElement('li');
        notificationItem.classList.add('dropdown-item');
        notificationItem.innerHTML = `
            <div class="notification-content">
                <a href="/tikects/detalles/${notification.tikect_id}/" class="text-decoration-none">
                    ${notification.descripcion}
                </a>
                <small class="text-muted d-block">Hace un momento</small>
            </div>
        `;
        dropdownMenu.appendChild(notificationItem);
    });
}

// Crear objeto de audio (comentado si no existe el archivo)
// const notificationSound = new Audio('/static/tikects_app/notification.mp3');

// Función para verificar nuevas notificaciones
let lastNotificationCount = 0;

function checkForNotifications() {
    fetch(notificationApiUrl)
        .then(response => {
            if (!response.ok) {
                throw new Error('Error en la respuesta del servidor');
            }
            return response.json();
        })
        .then(data => {
            if (data.new_notifications) {
                const currentNotificationCount = data.notifications.length;
                
                if (currentNotificationCount > lastNotificationCount) {
                    animateBell();
                    updateNotifications(data.notifications);
                    
                    // Reproducir sonido (comentado si no existe)
                    // notificationSound.play().catch(error => {
                    //     console.error('Error al reproducir el sonido:', error);
                    // });
                }
                
                lastNotificationCount = currentNotificationCount;
            }
        })
        .catch(error => console.error('Error fetching notifications:', error));
}

// Iniciar la verificación periódica
document.addEventListener('DOMContentLoaded', () => {
    // Verificar cada 30 segundos
    setInterval(checkForNotifications, 30000);
    // Verificar inmediatamente al cargar
    checkForNotifications();
});
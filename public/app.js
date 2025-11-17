// Contador de visitas y requests
let visitCount = 0;
let requestCount = 0;

// Incrementar visitas al cargar la página
window.addEventListener('load', () => {
    visitCount = parseInt(localStorage.getItem('visitCount') || '0') + 1;
    localStorage.setItem('visitCount', visitCount);
    document.getElementById('visits').textContent = visitCount;

    // Cargar estado inicial
    checkStatus();
    getInfo();
});

// Función para verificar el estado del servidor
async function checkStatus() {
    const statusDiv = document.getElementById('status');
    statusDiv.innerHTML = '<div class="loading">Checking status...</div>';

    try {
        const response = await fetch('/api/status');
        const data = await response.json();

        requestCount++;
        document.getElementById('requests').textContent = requestCount;

        statusDiv.innerHTML = `
            <div class="status-item">
                <strong>Status:</strong> <span class="status-online">${data.status.toUpperCase()}</span>
            </div>
            <div class="status-item">
                <strong>Message:</strong> ${data.message}
            </div>
            <div class="status-item">
                <strong>Timestamp:</strong> ${new Date(data.timestamp).toLocaleString('en-US')}
            </div>
            <div class="status-item">
                <strong>Version:</strong> ${data.version}
            </div>
        `;
    } catch (error) {
        statusDiv.innerHTML = `
            <div class="status-item">
                <strong>Status:</strong> <span class="status-offline">ERROR</span>
            </div>
            <div class="status-item">
                <strong>Details:</strong> Unable to connect to server
            </div>
        `;
    }
}

// Función para obtener información de la aplicación
async function getInfo() {
    const infoDiv = document.getElementById('info');
    infoDiv.innerHTML = '<div class="loading">Loading information...</div>';

    try {
        const response = await fetch('/api/info');
        const data = await response.json();

        requestCount++;
        document.getElementById('requests').textContent = requestCount;

        infoDiv.innerHTML = `
            <div class="info-item">
                <strong>Application:</strong> ${data.app}
            </div>
            <div class="info-item">
                <strong>Environment:</strong> ${data.environment}
            </div>
            <div class="info-item">
                <strong>Port:</strong> ${data.port}
            </div>
            <div class="info-item">
                <strong>Node Version:</strong> ${data.nodeVersion}
            </div>
        `;
    } catch (error) {
        infoDiv.innerHTML = `
            <div class="info-item">
                <strong>Error:</strong> Unable to retrieve application information
            </div>
        `;
    }
}

// Animación suave al hacer scroll
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth'
            });
        }
    });
});

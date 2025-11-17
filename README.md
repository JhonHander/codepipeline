# AWS Demo Application

Una aplicación Node.js sencilla y elegante para experimentos con AWS CodePipeline.

## 🚀 Características

- ✅ Servidor Express.js
- ✅ API REST con endpoints de estado
- ✅ Interfaz web moderna y responsiva
- ✅ Estadísticas en tiempo real
- ✅ Lista para deployment en AWS

## 📋 Requisitos

- Node.js 14+ 
- npm

## 🛠️ Instalación

```bash
npm install
```

## ▶️ Ejecución

```bash
npm start
```

La aplicación estará disponible en `http://localhost:3000`

## 📡 Endpoints

- `GET /` - Página principal
- `GET /api/status` - Estado del servidor
- `GET /api/info` - Información de la aplicación

## 🌐 Deployment en AWS

Esta aplicación está lista para ser desplegada en:
- AWS Elastic Beanstalk
- AWS EC2
- AWS ECS/Fargate
- AWS App Runner

## 📦 Estructura del Proyecto

```
.
├── server.js          # Servidor Express
├── package.json       # Dependencias
├── public/
│   ├── index.html    # Página principal
│   ├── styles.css    # Estilos
│   └── app.js        # JavaScript frontend
└── README.md         # Este archivo
```

## 🎯 Uso con AWS CodePipeline

1. Conecta tu repositorio a CodePipeline
2. Configura el build con CodeBuild
3. Despliega automáticamente con cada commit

## 📝 Notas

Aplicación creada para fines educativos y de demostración.

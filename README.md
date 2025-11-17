# AWS CI/CD Pipeline - Demo Application

Pipeline completo de CI/CD en AWS con ambientes de Staging y Production, aprobaciones manuales, y balanceadores de carga.

## 🏗️ Arquitectura

```
GitHub → CodePipeline → CodeBuild → ECR → ECS (Fargate)
                          ↓
                    [Aprobación Manual]
                          ↓
                    Staging (ALB)
                          ↓
                    [Aprobación Manual]
                          ↓
                    Production (ALB)
```

## ✨ Características del Pipeline

- ✅ **Integración Continua** con CodeBuild y Docker
- ✅ **Despliegue Continuo** automatizado a ECS Fargate
- ✅ **Dos Ambientes:** Staging y Production
- ✅ **Aprobaciones Manuales** antes de cada despliegue
- ✅ **Balanceadores de Carga** (ALB) en ambos ambientes
- ✅ **Health Checks** automáticos
- ✅ **Notificaciones SNS** para aprobaciones
- ✅ **Infrastructure as Code** con Terraform

## 📋 Componentes AWS

| Servicio | Propósito | Cantidad |
|----------|-----------|----------|
| CodePipeline | Orquestación del pipeline | 1 |
| CodeBuild | Build de imágenes Docker | 1 |
| ECR | Registro de imágenes Docker | 1 |
| ECS Fargate | Ejecución de contenedores | 2 servicios |
| ALB | Balanceo de carga | 2 (staging + prod) |
| VPC | Red privada virtual | 1 |
| SNS | Notificaciones | 1 topic |
| CloudWatch | Logs y monitoreo | 1 log group |
| S3 | Artifacts del pipeline | 1 bucket |

## 🚀 Quick Start

### 1. Clonar el Repositorio
```bash
git clone <tu-repo>
cd codepipe
```

### 2. Configurar Variables de Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:
```hcl
github_connection_arn = "arn:aws:codestar-connections:..."
github_repository     = "TuUsuario/tu-repo"
github_branch        = "main"
```

### 3. Desplegar Infraestructura
```bash
terraform init
terraform plan
terraform apply
```

### 4. Ver las URLs de los Balanceadores
```bash
terraform output
```

## 📱 Aplicación Demo

Una aplicación Node.js simple con:
- Servidor Express.js en puerto 3000
- Endpoint de health check: `/api/status`
- Interfaz web en `/`
- Dockerizada y lista para ECS

### Ejecución Local
```bash
npm install
npm start
```

Accede a: `http://localhost:3000`

## 📡 Endpoints de la Aplicación

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/` | GET | Página principal |
| `/api/status` | GET | Health check (usado por ALB) |
| `/api/info` | GET | Información de la aplicación |

## 🔧 Estructura del Proyecto

```
codepipe/
├── terraform/                    # Infraestructura como código
│   ├── main.tf                  # VPC, ECS, ALB, Networking
│   ├── codepipeline.tf          # CodePipeline, CodeBuild, IAM
│   ├── variables.tf             # Variables de entrada
│   ├── outputs.tf               # Outputs (URLs, ARNs)
│   └── terraform.tfvars         # Valores de variables (gitignored)
├── public/                       # Frontend de la aplicación
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── server.js                     # Backend Node.js/Express
├── package.json                  # Dependencias de Node.js
├── Dockerfile                    # Imagen Docker
├── buildspec.yml                 # Configuración de CodeBuild
├── DEPLOYMENT_INSTRUCTIONS.md    # Guía completa de despliegue
├── SOLUTION_SUMMARY.md           # Resumen de la solución
├── USEFUL_COMMANDS.md            # Comandos útiles de AWS
├── verify-and-deploy.ps1         # Script de despliegue automatizado
└── README.md                     # Este archivo
```

## 🔄 Flujo del Pipeline

1. **Source**: Detecta cambios en GitHub (branch: main)
2. **Build**: 
   - Construye imagen Docker
   - Sube a ECR
   - Genera `imagedefinitions.json`
3. **Deploy_Staging**: 
   - ⏸️ Espera aprobación manual
   - Despliega a ambiente de Staging
4. **Approve_Production**:
   - ⏸️ Espera aprobación manual
   - Notifica vía SNS
5. **Deploy_To_Production**:
   - Despliega a ambiente de Production
   - Health checks automáticos

## 🎯 Cómo Usar el Pipeline

### Hacer un Cambio
```bash
# Edita tu código
git add .
git commit -m "feat: nuevo feature"
git push origin main
```

### Aprobar Despliegues
1. Ve a AWS Console → CodePipeline
2. Selecciona `codepipe-pipeline`
3. Cuando veas "Deploy_Staging" en estado "Waiting for approval":
   - Haz clic en "Review"
   - Revisa los cambios
   - Haz clic en "Approve"
4. Repite para "Approve_Production"

### Verificar Despliegues
```bash
# Staging
curl http://$(cd terraform && terraform output -raw alb_staging_dns_name)/api/status

# Production
curl http://$(cd terraform && terraform output -raw alb_production_dns_name)/api/status
```

## 📊 Monitoreo

### CloudWatch Logs
```bash
aws logs tail /ecs/codepipe-app --follow --region us-east-1
```

### Estado del Pipeline
```bash
aws codepipeline get-pipeline-state --name codepipe-pipeline --region us-east-1
```

### Health de los Servicios ECS
```bash
# Staging
aws ecs describe-services --cluster codepipe-cluster --services codepipe-service-staging --region us-east-1

# Production
aws ecs describe-services --cluster codepipe-cluster --services codepipe-service-production --region us-east-1
```

## 🛡️ Seguridad

- VPC con subnets públicas en 2 AZs
- Security Groups restrictivos
- IAM Roles con permisos mínimos necesarios
- Imágenes Docker escaneadas en ECR
- Contenedores ejecutándose como usuario no-root

## 💰 Costos Estimados

| Servicio | Costo Aprox. (mensual) |
|----------|----------------------|
| ECS Fargate (2 tareas) | ~$36 |
| ALB (2 instancias) | ~$32 |
| ECR | ~$1 |
| CodeBuild | ~$5 (100 builds) |
| Otros (S3, CloudWatch, etc.) | ~$5 |
| **TOTAL** | **~$79/mes** |

*Nota: Costos pueden variar según uso y región*

## 🧹 Limpieza de Recursos

Para eliminar toda la infraestructura:

```bash
cd terraform
terraform destroy
```

⚠️ **ADVERTENCIA:** Esto eliminará:
- Todos los servicios ECS
- Balanceadores de carga
- VPC y networking
- ECR repository (y todas las imágenes)
- Logs de CloudWatch
- Pipeline de CodePipeline

## 🐛 Troubleshooting

### Error: "The provided role does not have sufficient permissions"
✅ **SOLUCIONADO** - Los permisos IAM han sido corregidos en la última versión

### El health check falla
- Verifica que tu aplicación responda en `/api/status` con código 200
- Revisa los logs: `aws logs tail /ecs/codepipe-app --follow`

### El pipeline no se activa automáticamente
- Verifica la conexión de CodeStar con GitHub
- Asegúrate de que estás haciendo push a la rama correcta (main)

### Las tareas ECS no se inician
- Revisa los logs de CloudWatch
- Verifica que la imagen existe en ECR
- Comprueba los security groups

Ver más en: **[USEFUL_COMMANDS.md](USEFUL_COMMANDS.md)**

## 📚 Documentación Adicional

- **[DEPLOYMENT_INSTRUCTIONS.md](DEPLOYMENT_INSTRUCTIONS.md)** - Guía completa de despliegue paso a paso
- **[SOLUTION_SUMMARY.md](SOLUTION_SUMMARY.md)** - Resumen de la arquitectura y solución
- **[USEFUL_COMMANDS.md](USEFUL_COMMANDS.md)** - Comandos AWS CLI útiles
- **[terraform/README.md](terraform/README.md)** - Documentación de Terraform

## 🎓 Proyecto Académico

Este proyecto fue desarrollado como parte de una actividad académica que requiere:

✅ Pipeline de CI/CD completo en AWS  
✅ Ambientes de Staging y Production  
✅ Aprobaciones manuales en cada etapa  
✅ Balanceadores de carga en ambos ambientes  
✅ Configuración en ECS con Fargate  
✅ Archivo buildspec.yml configurado  
✅ Integración con GitHub  

**Todos los requisitos han sido implementados satisfactoriamente.**

## 👥 Autor

JhonHander

## 📄 Licencia

Este proyecto es de código abierto para fines educativos.

---

**¿Necesitas ayuda?** Revisa [DEPLOYMENT_INSTRUCTIONS.md](DEPLOYMENT_INSTRUCTIONS.md) para instrucciones detalladas.

# Script de Verificación del Pipeline
# Este script te ayuda a verificar el estado del pipeline y los recursos

Write-Host "=== Verificación del Pipeline CI/CD AWS ===" -ForegroundColor Cyan
Write-Host ""

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "terraform\main.tf")) {
    Write-Host "ERROR: Este script debe ejecutarse desde el directorio raíz del proyecto" -ForegroundColor Red
    Write-Host "Directorio actual: $PWD" -ForegroundColor Yellow
    exit 1
}

Write-Host "1. Verificando archivos de configuración..." -ForegroundColor Yellow

$archivos = @(
    "terraform\main.tf",
    "terraform\codepipeline.tf",
    "terraform\variables.tf",
    "terraform\outputs.tf",
    "buildspec.yml",
    "Dockerfile"
)

foreach ($archivo in $archivos) {
    if (Test-Path $archivo) {
        Write-Host "   ✓ $archivo" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $archivo - NO ENCONTRADO" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "2. Próximos pasos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   A. Hacer commit de los cambios:" -ForegroundColor Cyan
Write-Host "      git add ." -ForegroundColor White
Write-Host "      git commit -m 'Fix: Corrección de permisos IAM para CodePipeline'" -ForegroundColor White
Write-Host "      git push origin main" -ForegroundColor White
Write-Host ""

Write-Host "   B. Aplicar cambios en Terraform:" -ForegroundColor Cyan
Write-Host "      cd terraform" -ForegroundColor White
Write-Host "      terraform plan" -ForegroundColor White
Write-Host "      terraform apply" -ForegroundColor White
Write-Host ""

Write-Host "   C. Verificar el Pipeline en AWS Console:" -ForegroundColor Cyan
Write-Host "      https://console.aws.amazon.com/codesuite/codepipeline/pipelines" -ForegroundColor White
Write-Host ""

Write-Host "=== Fin de la verificación ===" -ForegroundColor Cyan
Write-Host ""

# Preguntar si quiere continuar con git
$respuesta = Read-Host "¿Deseas hacer commit y push ahora? (s/n)"

if ($respuesta -eq 's' -or $respuesta -eq 'S') {
    Write-Host ""
    Write-Host "Ejecutando comandos de Git..." -ForegroundColor Yellow
    
    git add .
    git status
    
    Write-Host ""
    $mensaje = Read-Host "Ingresa el mensaje del commit (Enter para usar el mensaje por defecto)"
    
    if ([string]::IsNullOrWhiteSpace($mensaje)) {
        $mensaje = "Fix: Corrección de permisos IAM para CodePipeline y mejoras en ECS"
    }
    
    git commit -m $mensaje
    
    Write-Host ""
    $push = Read-Host "¿Hacer push a origin main? (s/n)"
    
    if ($push -eq 's' -or $push -eq 'S') {
        git push origin main
        Write-Host ""
        Write-Host "✓ Cambios enviados a GitHub exitosamente!" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANTE: Ahora debes aplicar los cambios en Terraform" -ForegroundColor Yellow
        Write-Host "Ejecuta:" -ForegroundColor Cyan
        Write-Host "   cd terraform" -ForegroundColor White
        Write-Host "   terraform apply" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "OK. Recuerda hacer commit y push manualmente antes de aplicar Terraform." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Para más información, consulta: DEPLOYMENT_INSTRUCTIONS.md" -ForegroundColor Cyan

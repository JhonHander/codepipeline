# Script de Monitoreo del Pipeline en Tiempo Real
# Ejecutar desde el directorio raíz del proyecto

param(
    [switch]$Continuous = $false,
    [int]$RefreshSeconds = 10
)

function Get-PipelineStatus {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          ESTADO DEL PIPELINE CI/CD AWS                        ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Cambiar al directorio terraform para obtener outputs
    Push-Location terraform
    
    try {
        # Obtener URLs de los balanceadores
        Write-Host "📡 ENDPOINTS DE LA APLICACIÓN" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        
        try {
            $stagingDns = terraform output -raw alb_staging_dns_name 2>$null
            $prodDns = terraform output -raw alb_production_dns_name 2>$null
            
            if ($stagingDns) {
                Write-Host "  Staging:    " -NoNewline -ForegroundColor White
                Write-Host "http://$stagingDns" -ForegroundColor Green
                Write-Host "              " -NoNewline
                Write-Host "http://$stagingDns/api/status" -ForegroundColor DarkGreen
            }
            
            if ($prodDns) {
                Write-Host "  Production: " -NoNewline -ForegroundColor White
                Write-Host "http://$prodDns" -ForegroundColor Green
                Write-Host "              " -NoNewline
                Write-Host "http://$prodDns/api/status" -ForegroundColor DarkGreen
            }
        }
        catch {
            Write-Host "  (Terraform outputs no disponibles)" -ForegroundColor DarkGray
        }
        
        Write-Host ""
        
        # Estado del Pipeline
        Write-Host "🔄 ESTADO DEL PIPELINE" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        
        $pipelineState = aws codepipeline get-pipeline-state --name codepipe-pipeline --region us-east-1 2>$null | ConvertFrom-Json
        
        if ($pipelineState) {
            foreach ($stage in $pipelineState.stageStates) {
                $stageName = $stage.stageName
                $status = $stage.latestExecution.status
                
                # Determinar emoji y color según el estado
                $emoji = switch ($status) {
                    "Succeeded" { "✅"; $color = "Green" }
                    "Failed" { "❌"; $color = "Red" }
                    "InProgress" { "⏳"; $color = "Yellow" }
                    "Stopped" { "⏹️"; $color = "DarkYellow" }
                    default { "⏸️"; $color = "Gray" }
                }
                
                Write-Host "  $emoji " -NoNewline
                Write-Host "$stageName" -NoNewline -ForegroundColor White
                Write-Host " → " -NoNewline -ForegroundColor DarkGray
                Write-Host "$status" -ForegroundColor $color
            }
        }
        else {
            Write-Host "  ⚠️  No se pudo obtener el estado del pipeline" -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # Servicios ECS
        Write-Host "🐳 SERVICIOS ECS" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        
        $services = aws ecs describe-services --cluster codepipe-cluster --services codepipe-service-staging codepipe-service-production --region us-east-1 2>$null | ConvertFrom-Json
        
        if ($services) {
            foreach ($service in $services.services) {
                $serviceName = $service.serviceName -replace "codepipe-service-", ""
                $desired = $service.desiredCount
                $running = $service.runningCount
                $status = $service.status
                
                $statusEmoji = if ($running -eq $desired -and $status -eq "ACTIVE") { "✅" } else { "⚠️" }
                
                Write-Host "  $statusEmoji " -NoNewline
                Write-Host "$serviceName" -NoNewline -ForegroundColor White
                Write-Host " → " -NoNewline -ForegroundColor DarkGray
                Write-Host "$running" -NoNewline -ForegroundColor $(if ($running -eq $desired) { "Green" } else { "Yellow" })
                Write-Host "/" -NoNewline -ForegroundColor DarkGray
                Write-Host "$desired" -NoNewline -ForegroundColor White
                Write-Host " tareas" -ForegroundColor DarkGray
                
                # Mostrar eventos recientes si hay problemas
                if ($running -ne $desired) {
                    $recentEvent = $service.events[0]
                    if ($recentEvent) {
                        Write-Host "       └─ $($recentEvent.message)" -ForegroundColor DarkYellow
                    }
                }
            }
        }
        else {
            Write-Host "  ⚠️  No se pudieron obtener los servicios ECS" -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # Target Groups Health
        Write-Host "🎯 HEALTH DE LOS BALANCEADORES" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        
        foreach ($tg in @("codepipe-tg-staging", "codepipe-tg-prod")) {
            $tgArn = aws elbv2 describe-target-groups --names $tg --query 'TargetGroups[0].TargetGroupArn' --output text --region us-east-1 2>$null
            
            if ($tgArn -and $tgArn -ne "None") {
                $health = aws elbv2 describe-target-health --target-group-arn $tgArn --region us-east-1 2>$null | ConvertFrom-Json
                
                $env = $tg -replace "codepipe-tg-", ""
                $healthyCount = ($health.TargetHealthDescriptions | Where-Object { $_.TargetHealth.State -eq "healthy" }).Count
                $totalCount = $health.TargetHealthDescriptions.Count
                
                $healthEmoji = if ($healthyCount -eq $totalCount -and $totalCount -gt 0) { "✅" } else { "⚠️" }
                
                Write-Host "  $healthEmoji " -NoNewline
                Write-Host "$env" -NoNewline -ForegroundColor White
                Write-Host " → " -NoNewline -ForegroundColor DarkGray
                
                if ($totalCount -gt 0) {
                    Write-Host "$healthyCount" -NoNewline -ForegroundColor $(if ($healthyCount -eq $totalCount) { "Green" } else { "Yellow" })
                    Write-Host "/" -NoNewline -ForegroundColor DarkGray
                    Write-Host "$totalCount" -NoNewline -ForegroundColor White
                    Write-Host " healthy" -ForegroundColor DarkGray
                }
                else {
                    Write-Host "Sin targets registrados" -ForegroundColor DarkGray
                }
            }
        }
        
        Write-Host ""
        
        # Última imagen en ECR
        Write-Host "📦 ÚLTIMA IMAGEN EN ECR" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        
        $images = aws ecr describe-images --repository-name aws-demo-app --region us-east-1 --query 'sort_by(imageDetails,& imagePushedAt)[-1]' 2>$null | ConvertFrom-Json
        
        if ($images) {
            $pushedAt = [DateTime]::Parse($images.imagePushedAt).ToLocalTime()
            $tags = $images.imageTags -join ", "
            
            Write-Host "  📅 Pushed: " -NoNewline -ForegroundColor White
            Write-Host "$($pushedAt.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
            Write-Host "  🏷️  Tags:   " -NoNewline -ForegroundColor White
            Write-Host "$tags" -ForegroundColor Cyan
        }
        else {
            Write-Host "  ⚠️  No se encontraron imágenes" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "Última actualización: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
        
    }
    finally {
        Pop-Location
    }
}

# Función para probar los endpoints
function Test-Endpoints {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              PRUEBA DE ENDPOINTS                               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Push-Location terraform
    
    try {
        $stagingDns = terraform output -raw alb_staging_dns_name 2>$null
        $prodDns = terraform output -raw alb_production_dns_name 2>$null
        
        foreach ($env in @(@{Name="Staging"; Dns=$stagingDns}, @{Name="Production"; Dns=$prodDns})) {
            if ($env.Dns) {
                Write-Host "🧪 Probando $($env.Name)..." -ForegroundColor Yellow
                
                try {
                    $response = Invoke-WebRequest -Uri "http://$($env.Dns)/api/status" -TimeoutSec 5 -ErrorAction Stop
                    
                    if ($response.StatusCode -eq 200) {
                        Write-Host "  ✅ Status Code: 200 OK" -ForegroundColor Green
                        
                        $json = $response.Content | ConvertFrom-Json
                        Write-Host "  📊 Response: " -NoNewline -ForegroundColor White
                        Write-Host "status=$($json.status), environment=$($json.environment)" -ForegroundColor Cyan
                    }
                }
                catch {
                    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Write-Host ""
            }
        }
    }
    finally {
        Pop-Location
    }
}

# Mostrar menú
if (-not $Continuous) {
    Get-PipelineStatus
    
    Write-Host ""
    Write-Host "OPCIONES:" -ForegroundColor Cyan
    Write-Host "  1. Refrescar estado" -ForegroundColor White
    Write-Host "  2. Modo continuo (actualización cada $RefreshSeconds segundos)" -ForegroundColor White
    Write-Host "  3. Probar endpoints" -ForegroundColor White
    Write-Host "  4. Ver logs recientes" -ForegroundColor White
    Write-Host "  5. Reiniciar pipeline" -ForegroundColor White
    Write-Host "  Q. Salir" -ForegroundColor White
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción"
    
    switch ($option) {
        "1" {
            & $MyInvocation.MyCommand.Path
        }
        "2" {
            & $MyInvocation.MyCommand.Path -Continuous
        }
        "3" {
            Test-Endpoints
            Read-Host "`nPresiona Enter para continuar"
            & $MyInvocation.MyCommand.Path
        }
        "4" {
            Write-Host "`nObteniendo últimos logs..." -ForegroundColor Yellow
            aws logs tail /ecs/codepipe-app --since 5m --region us-east-1
            Read-Host "`nPresiona Enter para continuar"
            & $MyInvocation.MyCommand.Path
        }
        "5" {
            Write-Host "`nReiniciando pipeline..." -ForegroundColor Yellow
            aws codepipeline start-pipeline-execution --name codepipe-pipeline --region us-east-1
            Write-Host "✅ Pipeline reiniciado" -ForegroundColor Green
            Start-Sleep -Seconds 2
            & $MyInvocation.MyCommand.Path
        }
        "q" {
            Write-Host "`n¡Hasta luego!" -ForegroundColor Cyan
            exit
        }
        "Q" {
            Write-Host "`n¡Hasta luego!" -ForegroundColor Cyan
            exit
        }
        default {
            & $MyInvocation.MyCommand.Path
        }
    }
}
else {
    # Modo continuo
    Write-Host "Modo continuo activado. Presiona Ctrl+C para salir.`n" -ForegroundColor Cyan
    
    while ($true) {
        Clear-Host
        Get-PipelineStatus
        Start-Sleep -Seconds $RefreshSeconds
    }
}

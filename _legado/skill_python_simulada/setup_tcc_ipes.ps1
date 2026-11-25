# Setup TCC Ipês — Instalação Ambiente Completo
# Autor: Milton Bacuau
# Data: 2026-11-24
# Script: Instala R, Python, pacotes — Windows 10/11

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "SETUP TCC — Modelagem Ambiental de Ipês" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar privilégios admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "❌ Este script requer privilégios de Administrador!" -ForegroundColor Red
    Write-Host "Execute: Right-click PowerShell → 'Run as administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Privilégios de administrador confirmados" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 1. VERIFICAR PYTHON
# ============================================================================
Write-Host "[1/4] Verificando Python..." -ForegroundColor Cyan
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Python encontrado: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  Python não encontrado. Instale manualmente em https://www.python.org/" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# 2. INSTALAR R
# ============================================================================
Write-Host "[2/4] Verificando/Instalando R..." -ForegroundColor Cyan

$rExe = "C:\Program Files\R\R-4.3.3\bin\Rscript.exe"
$rCheck = Test-Path $rExe

if ($rCheck) {
    Write-Host "✅ R já instalado: $rExe" -ForegroundColor Green
} else {
    Write-Host "📥 Baixando R-4.3.3 para Windows..." -ForegroundColor Yellow

    $rUrl = "https://cran.r-project.org/bin/windows/base/R-4.3.3-win.exe"
    $rInstaller = "$env:TEMP\R-4.3.3-win.exe"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile($rUrl, $rInstaller)
        Write-Host "✅ Download completo: $rInstaller" -ForegroundColor Green

        Write-Host "🔧 Executando instalador R..." -ForegroundColor Yellow
        & $rInstaller /SILENT /DIR="C:\Program Files\R\R-4.3.3"

        Write-Host "✅ R instalado com sucesso" -ForegroundColor Green
        Write-Host "   Localização: C:\Program Files\R\R-4.3.3" -ForegroundColor Green

        Start-Sleep -Seconds 5
    } catch {
        Write-Host "❌ Erro ao baixar/instalar R: $_" -ForegroundColor Red
        Write-Host "   Instale manualmente em https://cran.r-project.org/" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 3. INSTALAR PACOTES R
# ============================================================================
Write-Host "[3/4] Verificando/Instalando pacotes R..." -ForegroundColor Cyan

$rscript = "Rscript"
$packagesNeeded = @("maxnet", "ecospat", "raster", "sp")

foreach ($pkg in $packagesNeeded) {
    Write-Host "   Verificando $pkg..." -ForegroundColor Cyan
    $checkPkg = & $rscript -e "if (!require('$pkg', quietly=TRUE)) { quit(status=1) }" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $pkg já instalado" -ForegroundColor Green
    } else {
        Write-Host "   📥 Instalando $pkg..." -ForegroundColor Yellow
        & $rscript -e "install.packages('$pkg', repos='https://cran.r-project.org/', quiet=TRUE)"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ $pkg instalado" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Erro ao instalar $pkg" -ForegroundColor Red
        }
    }
}

Write-Host ""

# ============================================================================
# 4. VERIFICAR AMBIENTE FINAL
# ============================================================================
Write-Host "[4/4] Verificação Final..." -ForegroundColor Cyan

$allOk = $true

# Python
$pythonOk = (python --version 2>&1) -and ($LASTEXITCODE -eq 0)
if ($pythonOk) {
    $pythonVer = python --version 2>&1
    Write-Host "✅ Python: $pythonVer" -ForegroundColor Green
} else {
    Write-Host "❌ Python: Não encontrado" -ForegroundColor Red
    $allOk = $false
}

# R
$rOk = (Rscript --version 2>&1) -and ($LASTEXITCODE -eq 0)
if ($rOk) {
    $rVer = Rscript --version 2>&1
    Write-Host "✅ R: $rVer" -ForegroundColor Green
} else {
    Write-Host "❌ R: Não encontrado" -ForegroundColor Red
    $allOk = $false
}

# Diretórios
$dataDir = "C:\Users\jotac\Downloads\TCC MILTON\TCC - Ipes - Inicio do zero"
$r28Dir = Join-Path $dataDir "05 - Modelagem no R\R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO"
$r30Dir = Join-Path $dataDir "05 - Modelagem no R\R30_TCC_IPES_GRADE_72_UPAS_V1"
$r31Dir = Join-Path $dataDir "05 - Modelagem no R\R31_TCC_IPES_VALIDACAO_EXTERNA_V1"

$dirsOk = (Test-Path $r28Dir) -and (Test-Path $r30Dir) -and (Test-Path $r31Dir)
if ($dirsOk) {
    Write-Host "✅ Diretórios projeto: OK (R28, R30, R31)" -ForegroundColor Green
} else {
    Write-Host "❌ Diretórios projeto: Incompletos" -ForegroundColor Red
    $allOk = $false
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan

if ($allOk) {
    Write-Host "✅ SETUP COMPLETO — Pronto para executar skill!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximo passo:" -ForegroundColor Cyan
    Write-Host "  python skill_modelagem_ipes.py" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tempo estimado skill:" -ForegroundColor Cyan
    Write-Host "  R28 (6 modelos): ~1 hora" -ForegroundColor Yellow
    Write-Host "  R30 (72 modelos): ~2 horas" -ForegroundColor Yellow
    Write-Host "  R31 (validação): ~1 hora" -ForegroundColor Yellow
    Write-Host "  Total: ~4-5 horas" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  SETUP INCOMPLETO — Veja erros acima" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checklist:" -ForegroundColor Cyan
    Write-Host "  ☐ Python ≥ 3.8 instalado" -ForegroundColor Yellow
    Write-Host "  ☐ R ≥ 4.0 instalado" -ForegroundColor Yellow
    Write-Host "  ☐ Pacotes R (maxnet, ecospat, raster, sp) instalados" -ForegroundColor Yellow
    Write-Host "  ☐ Diretórios TCC - Ipes - Inicio do zero/ existem" -ForegroundColor Yellow
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Logs
$logFile = "C:\Users\jotac\Downloads\TCC MILTON\setup_tcc_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Write-Host "Log: $logFile" -ForegroundColor Gray

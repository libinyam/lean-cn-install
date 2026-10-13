# Install-Lean.ps1 — 一键安装 Lean 4（走上海交大镜像，避免官方源龟速）
# 用法：
#   双击"一键安装Lean.bat"          —— 安装最新稳定版
#   或在终端里指定版本：
#   powershell -ExecutionPolicy Bypass -File Install-Lean.ps1 -Version 4.34.1
param(
    [string]$Version = "latest"   # 默认自动查询镜像上的最新稳定版
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Mirror   = "https://mirror.sjtu.edu.cn/elan"
$ElanDir  = Join-Path $env:USERPROFILE ".elan"
$ElanExe  = Join-Path $ElanDir "bin\elan.exe"
$WorkDir  = Join-Path $env:TEMP ("lean-install-" + [Guid]::NewGuid().ToString("N").Substring(0,8))

function Info($msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[√] $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "[×] $msg" -ForegroundColor Red; exit 1 }

New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
try {
    # ---------- 1. 确定要装的版本 ----------
    if ($Version -eq "latest") {
        Info "正在从镜像站查询最新稳定版..."
        $html = (Invoke-WebRequest -Uri "$Mirror/leanprover/lean4/releases/download/mirror_clone_list.html" -UseBasicParsing).Content
        $vers = [regex]::Matches($html, 'v(\d+\.\d+\.\d+)/mirror_clone_list\.html') |
                ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
        if (-not $vers) { Fail "无法从镜像站获取版本列表" }
        $Version = ($vers | Sort-Object { [version]$_ } | Select-Object -Last 1)
    }
    $Version = $Version.TrimStart('v')
    Ok "目标版本：Lean $Version"

    # ---------- 2. 确保 elan 已安装 ----------
    if (Test-Path $ElanExe) {
        Ok "elan 已安装，跳过"
    } else {
        Info "未检测到 elan，从镜像站下载安装..."
        $elanHtml = (Invoke-WebRequest -Uri "$Mirror/elan/releases/download/mirror_clone_list.html" -UseBasicParsing).Content
        $elanVer  = ([regex]::Matches($elanHtml, 'v(\d+\.\d+\.\d+)/mirror_clone_list\.html') |
                     ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique |
                     Sort-Object { [version]$_ } | Select-Object -Last 1)
        if (-not $elanVer) { Fail "无法获取 elan 版本列表" }
        $zip = Join-Path $WorkDir "elan.zip"
        curl.exe -L -o $zip "$Mirror/elan/releases/download/v$elanVer/elan-x86_64-pc-windows-msvc.zip"
        if ($LASTEXITCODE -ne 0) { Fail "elan 下载失败" }
        Expand-Archive -Path $zip -DestinationPath (Join-Path $WorkDir "elan") -Force
        & (Join-Path $WorkDir "elan\elan-init.exe") -y --default-toolchain none
        if ($LASTEXITCODE -ne 0) { Fail "elan 安装失败" }
        $env:PATH = "$ElanDir\bin;$env:PATH"
        Ok "elan $elanVer 安装完成"
    }

    # ---------- 3. 安装 Lean 工具链 ----------
    $tcName = "leanprover--lean4---v$Version"
    $tcDir  = Join-Path $ElanDir "toolchains\$tcName"
    if (Test-Path (Join-Path $tcDir "bin\lean.exe")) {
        Ok "Lean $Version 工具链已存在，跳过下载"
    } else {
        Info "下载 Lean $Version（约 850 MB，镜像站速度通常几 MB/s）..."
        $zip = Join-Path $WorkDir "lean.zip"
        curl.exe -L -o $zip "$Mirror/leanprover/lean4/releases/download/v$Version/lean-$Version-windows.zip"
        if ($LASTEXITCODE -ne 0) { Fail "工具链下载失败，请检查版本号是否正确" }
        Info "解压中（约 1-2 分钟）..."
        Expand-Archive -Path $zip -DestinationPath (Join-Path $WorkDir "lean") -Force
        New-Item -ItemType Directory -Force -Path $tcDir | Out-Null
        Move-Item (Join-Path $WorkDir "lean\lean-$Version-windows\*") $tcDir
        Ok "工具链解压到 $tcDir"
    }

    # ---------- 4. 固定默认版本（关键：避免 elan 每次联网解析 stable） ----------
    Info "将默认工具链固定为 v$Version ..."
    & $ElanExe default "leanprover/lean4:v$Version" | Out-Null

    # ---------- 5. 验证 ----------
    $env:PATH = "$ElanDir\bin;$env:PATH"
    $verOut = & lean --version 2>&1
    if ($LASTEXITCODE -ne 0) { Fail "验证失败：lean --version 执行出错" }
    Ok "安装完成！$verOut"
    Write-Host ""
    Write-Host "提示：VS Code 里装 leanprover.lean4 插件后打开 .lean 文件即可使用。" -ForegroundColor Yellow
    Write-Host "如果之前在 VS Code 里卡 'Checking Lean version'，重启 VS Code 即可。" -ForegroundColor Yellow
}
finally {
    Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue
}

# Install-Mathlib.ps1 — 创建 Mathlib 项目并拉取预编译缓存（国内镜像加速版）
# 前提：已装好 Lean 环境（先运行 Install-Lean.ps1）
# 用法：
#   powershell -ExecutionPolicy Bypass -File Install-Mathlib.ps1                  # 项目名默认 my_math_project
#   powershell -ExecutionPolicy Bypass -File Install-Mathlib.ps1 -ProjectName demo
param(
    [string]$ProjectName = "my_math_project"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Mirror    = "https://mirror.sjtu.edu.cn"
$GitMirror = "$Mirror/git/lean4-packages"
$Here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$LeanEnv   = Join-Path $Here "Install-Lean.ps1"

function Info($msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[√] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[×] $msg" -ForegroundColor Red; exit 1 }

# ---------- 0. 检查基础环境 ----------
if (-not (Get-Command elan -ErrorAction SilentlyContinue)) {
    $env:PATH = "$env:USERPROFILE\.elan\bin;$env:PATH"
}
if (-not (Get-Command elan -ErrorAction SilentlyContinue)) {
    Fail "未检测到 Lean 环境，请先运行 Install-Lean.ps1"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "未检测到 git，请先安装 Git for Windows"
}
Ok "Lean 环境已就绪"

# ---------- 1. 给 git 配置镜像重写规则（仅对镜像站确实存在的仓库生效） ----------
function Add-MirrorRule($repo) {
    $mirrorUrl = "$GitMirror/$repo/"
    $null = git ls-remote $mirrorUrl HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        git config --global "url.$mirrorUrl.insteadOf" "https://github.com/leanprover-community/$repo"
        Ok "镜像重写：leanprover-community/$repo -> SJTUG"
    } else {
        Warn "镜像站没有 $repo，该仓库仍走 GitHub（可能较慢）"
    }
}

Info "配置 git 镜像重写规则..."
Add-MirrorRule "mathlib4"

# ---------- 2. 创建（或续建）项目 ----------
if (Test-Path (Join-Path $ProjectName "lakefile.toml")) {
    Ok "项目 $ProjectName 已存在，继续配置"
} elseif (Test-Path (Join-Path $ProjectName "lakefile.lean")) {
    Ok "项目 $ProjectName 已存在，继续配置"
} else {
    Info "创建项目 $ProjectName（模板：math）..."
    lake new $ProjectName math
    if ($LASTEXITCODE -ne 0) { Fail "lake new 失败" }
    Ok "项目创建完成"
}
Set-Location $ProjectName

# ---------- 3. 按项目要求安装对应版本的工具链（走镜像，避免 elan 走官方慢速源） ----------
$tc = (Get-Content lean-toolchain -Raw).Trim()
if ($tc -match 'v(\d+\.\d+\.\d+[-\w.]*)') {
    $needVer = $Matches[1]
    Info "项目要求工具链 v$needVer，确保已安装..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $LeanEnv -Version $needVer
    if ($LASTEXITCODE -ne 0) { Fail "工具链 v$needVer 安装失败" }
} else {
    Warn "无法解析 lean-toolchain 版本：$tc"
}

# ---------- 4. 为 mathlib 的依赖仓库配置镜像 ----------
$mathlibManifest = ".lake/packages/mathlib/lake-manifest.json"
if (Test-Path $mathlibManifest) {
    Info "检查 mathlib 依赖仓库的镜像可用性..."
    $manifest = Get-Content $mathlibManifest -Raw | ConvertFrom-Json
    foreach ($pkg in $manifest.packages) {
        $url = $pkg.url
        if ($url -match 'github\.com/leanprover-community/([^/]+?)(\.git)?$') {
            Add-MirrorRule $Matches[1]
        }
    }
}

# ---------- 5. 拉取预编译缓存（跳过数小时的源码编译） ----------
Info "拉取 Mathlib 预编译缓存（lake exe cache get，几个 GB，请耐心等待）..."
lake exe cache get
if ($LASTEXITCODE -ne 0) { Fail "缓存拉取失败。若速度过慢可 Ctrl+C 后重试，断点会续传已下载部分" }
Ok "缓存拉取完成"

# ---------- 6. 构建验证 ----------
Info "构建项目验证..."
lake build
if ($LASTEXITCODE -ne 0) { Fail "lake build 失败" }
Ok "Mathlib 项目 $ProjectName 配置完成！"
Write-Host ""
Write-Host "用 VS Code 打开 $ProjectName 文件夹即可开始使用 Mathlib。" -ForegroundColor Yellow
Write-Host "试试在文件里写：import Mathlib 然后 #eval (2 + 2 : Nat)" -ForegroundColor Yellow

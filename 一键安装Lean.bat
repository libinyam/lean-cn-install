@echo off
chcp 65001 >nul
title Lean 4 一键安装（国内镜像版）
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Lean.ps1" %*
pause

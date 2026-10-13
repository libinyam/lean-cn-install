@echo off
chcp 65001 >nul
title Mathlib 项目一键创建（国内镜像版）
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Mathlib.ps1" %*
pause

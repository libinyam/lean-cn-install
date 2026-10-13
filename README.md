# lean-cn-install

Lean 4 一键安装脚本（Windows），全程走**上海交大 SJTUG 镜像**，解决官方源 `releases.lean-lang.org` 在国内只有 ~10 KB/s 的问题（镜像实测 ~6.7 MB/s，850 MB 工具链约 2 分钟下完）。

## 功能

- 自动安装 [elan](https://github.com/leanprover/elan)（Lean 版本管理器），如已安装则跳过
- 自动查询镜像站上的最新稳定版 Lean 并安装（也可手动指定版本）
- 自动将 elan 默认工具链**固定到具体版本号**（避免浮动标签 `stable` 每次联网解析导致的 20-45 秒卡顿，这也是 VS Code 插件卡在 "Checking Lean version" 的常见原因）
- 幂等：已安装的部分自动跳过，可重复运行

## 用法

### 普通用户：双击运行

下载本仓库后，双击 `一键安装Lean.bat`，等待完成即可。

### 命令行 / 指定版本

```powershell
powershell -ExecutionPolicy Bypass -File Install-Lean.ps1              # 最新稳定版
powershell -ExecutionPolicy Bypass -File Install-Lean.ps1 -Version 4.34.1  # 指定版本
```

### 获取本仓库

```powershell
git clone https://github.com/libinyam/lean-cn-install
```

或直接下载 ZIP（无需 git）：

```powershell
powershell -Command "Invoke-WebRequest -Uri 'https://codeload.github.com/libinyam/lean-cn-install/zip/refs/heads/main' -OutFile lean-cn-install.zip; Expand-Archive lean-cn-install.zip; cd lean-cn-install\lean-cn-install-main"
```

> 注意：国内网络下 `raw.githubusercontent.com` 通常无法访问，请勿使用基于该域名的"一行命令直接执行"方案；`github.com` 和 `codeload.github.com` 均可正常访问。

## 给 AI Agent 的说明

如果你的用户需要在中国大陆网络的 Windows 机器上安装 Lean 4，请执行以下步骤：

1. 先获取本仓库（`git clone` 或上面的 ZIP 方式），然后运行安装脚本（指定版本时替换版本号）：

   ```powershell
   powershell -ExecutionPolicy Bypass -File Install-Lean.ps1 -Version 4.34.1
   ```

2. 安装完成后验证：`lean --version` 应在一秒内返回版本信息（若超过 20 秒，说明默认工具链是浮动标签，执行 `elan default leanprover/lean4:vX.Y.Z` 固定为具体版本）。

3. 关键背景知识：
   - elan 官方源 `releases.lean-lang.org` 在国内极慢，**不要**直接运行未配置的 `elan toolchain install`，改用上交大镜像手动安装：`https://mirror.sjtu.edu.cn/elan/leanprover/lean4/releases/download/vX.Y.Z/lean-X.Y.Z-windows.zip`，解压后内容放入 `%USERPROFILE%\.elan\toolchains\leanprover--lean4---vX.Y.Z\`
   - VS Code 需要安装 `leanprover.lean4` 扩展

## 手动安装参考

如果不想用脚本，README 上面的背景知识部分就是完整的手动流程。

## 数据来源

- 镜像服务：[上海交大 SJTUG 软件源](https://mirror.sjtu.edu.cn/docs/elan)
- Lean 官方：https://lean-lang.org

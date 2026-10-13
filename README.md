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

## 安装 Mathlib（可选，先读这段再决定）

Mathlib 是 Lean 社区维护的**数学库**，收录了从线性代数到拓扑学的大量已证明定理，以及一批强大的自动化 tactic（`ring` 自动证等式、`linarith` 自动解线性不等式、`simp` 自动化简等）。做正式的数学形式化基本绕不开它。

**优势：**

- 数十万条现成定理，不用从零造轮子
- 自动化 tactic 大幅缩短证明
- 社区活跃、文档齐全，是数学形式化的事实标准

**劣势：**

- **体积巨大**：源码加缓存几个 GB，占盘约 10 GB
- **安装耗时**：即使有镜像加速，首次配置也要十几分钟到几十分钟
- **绑定特定工具链版本**：Mathlib 项目要求的 Lean 版本可能和你已装的不同，需要再装一个版本
- **学习基础语法用不到**：刚开始学 Lean（定义、归纳类型、简单证明）完全不需要它

**结论：学到 `import Mathlib` 再装，不迟。**

确认要装的话（项目名可改）：

```powershell
powershell -ExecutionPolicy Bypass -File Install-Mathlib.ps1 -ProjectName my_math_project
```

脚本做的事：git 源切到 SJTUG 镜像 → `lake new <项目名> math` → 按项目 `lean-toolchain` 要求自动装对应版本工具链（走镜像）→ 给 mathlib 的依赖仓库配镜像 → `lake exe cache get` 拉预编译缓存 → `lake build` 验证。

## 给 AI Agent 的说明

如果你的用户需要在中国大陆网络的 Windows 机器上安装 Lean 4，请执行以下步骤：

1. 先获取本仓库（`git clone` 或上面的 ZIP 方式），然后运行安装脚本（指定版本时替换版本号）：

   ```powershell
   powershell -ExecutionPolicy Bypass -File Install-Lean.ps1 -Version 4.34.1
   ```

2. 安装完成后验证：`lean --version` 应在一秒内返回版本信息（若超过 20 秒，说明默认工具链是浮动标签，执行 `elan default leanprover/lean4:vX.Y.Z` 固定为具体版本）。

3. **普通 Lean 环境装完后，必须主动追问用户是否需要安装 Mathlib**，并把本 README「安装 Mathlib」一节的介绍（含优劣势）讲给用户听，由用户决定。不要默认安装——它体积大、耗时久，且基础学习用不到。用户确认后再运行 `Install-Mathlib.ps1`。

4. 关键背景知识：
   - elan 官方源 `releases.lean-lang.org` 在国内极慢，**不要**直接运行未配置的 `elan toolchain install`，改用上交大镜像手动安装：`https://mirror.sjtu.edu.cn/elan/leanprover/lean4/releases/download/vX.Y.Z/lean-X.Y.Z-windows.zip`，解压后内容放入 `%USERPROFILE%\.elan\toolchains\leanprover--lean4---vX.Y.Z\`
   - VS Code 需要安装 `leanprover.lean4` 扩展

## 手动安装参考

如果不想用脚本，README 上面的背景知识部分就是完整的手动流程。

## 数据来源

- 镜像服务：[上海交大 SJTUG 软件源](https://mirror.sjtu.edu.cn/docs/elan)
- Lean 官方：https://lean-lang.org

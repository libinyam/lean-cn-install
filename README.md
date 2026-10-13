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

## 常见问题

**新开终端提示找不到 `lean` / `elan` 命令？**

elan 安装时会把 `%USERPROFILE%\.elan\bin` 写入用户 PATH，但**已经打开的终端和程序不会自动刷新环境变量**。解决办法（任选其一）：

- 关掉终端重新打开（最简单）
- VS Code 里按 `Ctrl+Shift+P` → `Developer: Reload Window`，或直接重启 VS Code
- 都不生效就注销/重启一次电脑

若重装后仍找不到，检查系统环境变量 Path 里是否有 `C:\Users\<用户名>\.elan\bin`。

## 安装后：VS Code 插件（必装）

Lean 装好后，还需要在 VS Code 里安装 **Lean 4 插件** 才能获得语法高亮、实时检查、InfoView 证明状态面板等功能。脚本会尝试自动安装（检测到 VS Code 时）；如果没有自动装上，手动安装方法如下：

**方法一：图形界面（推荐新手）**

1. 打开 VS Code
2. 点左侧边栏的**扩展图标**（四个方块，或按 `Ctrl+Shift+X`）
3. 搜索框输入 `lean4`
4. 找到发布者为 **leanprover** 的 `Lean 4` 扩展，点 **Install**

**方法二：命令行**

```powershell
code --install-extension leanprover.lean4
```

安装后**重启 VS Code**，打开任意 `.lean` 文件，右下角出现 `lean4` 字样、右侧 InfoView 面板能显示信息，即为成功。若启动时卡在 "Checking Lean version" 超过 20 秒，说明默认工具链没固定，执行 `elan default leanprover/lean4:vX.Y.Z`（本脚本已自动处理）。

## Lean 文件命名规范

新建练习/项目文件时请遵守：

- **后缀必须是 `.lean`**，否则插件不会启用
- **文件名首字母大写**：`Test.lean`、`MyProof.lean` ✅；`test.lean` ❌
- **只用字母和数字**：不要出现连字符、空格、下划线开头等——`lean-1.lean`、`my proof.lean` 这类名字在做项目时会导致模块名非法
- **多单词用大驼峰**：`NatLemmas.lean`、`BasicAlgebra.lean`
- 项目里**文件路径即模块名**：`MyProject/Basic/Lemmas.lean` 对应 `import MyProject.Basic.Lemmas`，所以目录名同样要遵守上述规则

单个随手练习的文件不遵守也能跑，但建议从一开始就养成习惯。

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
   - 安装完成后**主动询问用户是否需要安装 VS Code 的 Lean 4 插件**（简要说明作用：语法高亮、实时检查、InfoView 证明面板）。用户同意后，执行 `code --install-extension leanprover.lean4` 帮忙安装。仅当 `code` 命令不可用（VS Code 未安装或未加入 PATH）时，才引导用户按「安装后：VS Code 插件」一节手动操作
   - **提醒用户遵守 .lean 文件命名规范**（首字母大写、只用字母数字），见上文「Lean 文件命名规范」一节
   - 若安装后终端提示找不到 `lean`/`elan`，是 PATH 未刷新，见上文「常见问题」一节

## 手动安装参考

如果不想用脚本，README 上面的背景知识部分就是完整的手动流程。

## 数据来源

- 镜像服务：[上海交大 SJTUG 软件源](https://mirror.sjtu.edu.cn/docs/elan)
- Lean 官方：https://lean-lang.org

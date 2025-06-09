---
title: 如何更好的使用 Windows 终端
date: 2025-06-09T04:37:30+08:00
draft: false
categories:
  - Windows
tags:
  - PowerShell
  - Windows Terminal
  - Nerd Fonts
  - Oh My Posh
  - Scoop
  - 开发者工具
  - 个性化配置
  - winget
---

# 安装 PowerShell

官方安装教程

https://learn.microsoft.com/zh-cn/powershell/scripting/install/installing-powershell?view=powershell-7.5

查找 PowerShell 版本

```PowerShell
winget search Microsoft.PowerShell
```

```Output
Name               Id                           Version Source
---------------------------------------------------------------
PowerShell         Microsoft.PowerShell         7.5.1.0 winget
PowerShell Preview Microsoft.PowerShell.Preview 7.6.0.4 winget
```

进行安装

```PowerShell
winget install --id Microsoft.PowerShell --source winget
```

```PowerShell
winget install --id Microsoft.PowerShell.Preview --source winget
```

## 配置 PowerShell

首次在系统上安装 PowerShell 时，配置文件脚本文件和它们所属的目录不存在。 以下命令创建“当前用户，当前主机”配置文件脚本文件（如果不存在）。

```PowerShell
if (!(Test-Path -Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force
}
```

添加个性化设置

```ps1
function desk { Set-Location "C:\Users\docke\Desktop" }
function gitl { git log --oneline --graph --decorate }
function ep { code $PROFILE }
function hosts { notepad C:\Windows\System32\drivers\etc\hosts }
function vim { nvim $args }
```

# 安装 Windows 终端

官方安装教程

https://learn.microsoft.com/zh-cn/windows/terminal/install

根据页面自行定制化设置即可，需确认好终端已将前边最新 PowerShell 设置为默认值。

# 安装 Nerd Fonts 字体

官网： https://www.nerdfonts.com/

Nerd Fonts 是一个为开发者量身定制的字体资源网站，通过将编程字体与图标字体结合，提供了一种功能强大且美观的方式来优化开发环境。无论是提升终端的视觉效果，还是增强代码的可读性和个性化，它都是一个非常有价值的工具。如果你是程序员或终端用户，这个网站值得一试。

其中我个人比较喜欢使用 JetBrainsMono Nerd Font。

# 安装 Oh My Posh

官方安装教程

https://ohmyposh.dev/

推荐 winget 安装。

安装后在 PowerShell 配置文件中增加启动项，这里使用了自带的 jandedobbeleer 主题，这也是作者自己的主题。

```ps1
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/jandedobbeleer.omp.json" | Invoke-Expression
```

创建或修改 `$PROFILE` 文件后，需要重载它以应用更改。运行以下命令：

```PowerShell
. $PROFILE
```

Oh My Posh 同样支持使用远程配置（但个人实测会有卡顿），本地配置会更加流畅。

# 安装 Scoop

Scoop 是一款适用于 Windows 的命令行包管理器，类似于 Linux 上的 apt 或 macOS 上的 Homebrew。它可以帮助用户快速安装和管理软件，尤其适合开发者或喜欢命令行操作的用户。

主要参考此仓库教程： https://github.com/ScoopInstaller/Install

进行高级安装，可以下载安装程序并手动执行它，并附带参数。

```PowerShell
irm get.scoop.sh -outfile 'install.ps1'
```

可以将 Scoop 安装到自定义目录，配置 Scoop 将全局程序安装到自定义目录，并在安装过程中绕过系统代理。

```powershell
.\install.ps1 -ScoopDir 'D:\Applications\Scoop' -ScoopGlobalDir 'F:\GlobalScoopApps' -NoProxy
```

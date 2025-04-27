---
title: How To Build A Hugo Blog From Scratch
date: 2025-04-15T02:55:35+08:00
draft: true
categories:
tags:
---

# 安装

通过包管理器安装。

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install hugo
# 卸载 Hugo 软件包。
sudo apt remove hugo
# 完全卸载 Hugo 软件包，包括配置文件。
sudo apt purge hugo
# 自动移除不再需要的软件包。
sudo apt autoremove
```

通过包安装。

```bash
sudo apt install ./hugo_extended_0.145.0_linux-amd64.deb
```

验证

```bash
hugo version
```

# 全流程

```
hugo new site 404-blog
cd 404-blog
git init
git config user.name "404"
git config user.email "404@example.com"
git add .
git commit -m "Initial commit"
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
echo "theme = 'PaperMod'" >> hugo.toml
创建 .gitignore
git add .
git commit -m "Add PaperMod theme and .gitignore file"
hugo server
```

# 引入配置

# 引入 GitHub action

要实现每次推送到 GitHub 仓库时，自动构建 Hugo 博客并部署到云服务器的 Nginx 下，您需要完成以下步骤：

## 1. 准备云服务器

首先，确保您的云服务器已安装 Nginx：

```bash
# Ubuntu/Debian
sudo apt update && sudo apt full-upgrade -y
sudo apt install nginx
```

## 2. 配置 Nginx

创建一个站点配置文件：

```bash
sudo vim /etc/nginx/sites-available/your-blog
```

添加以下配置（根据需要调整）：

```nginx
# 处理非www域名到www域名的重定向
server {
    listen 80;
    server_name 404blog.org;  # 非www域名
    
    # 301永久重定向到www版本
    return 301 $scheme://www.404blog.org$request_uri;
}

# 主域名的服务器配置
server {
    listen 80;
    server_name www.404blog.org;  # 主域名(www版本)
    
    root /var/www/404-blog;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}

```

启用站点并创建部署目录：

```bash
sudo ln -s /etc/nginx/sites-available/your-blog /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/your-blog
sudo chown -R $USER:$USER /var/www/your-blog  # 确保部署用户有权限
sudo nginx -t  # 测试配置
sudo systemctl reload nginx
```

## 3. 准备 SSH 密钥对

为了让 GitHub Actions 能够安全地连接到您的服务器，创建一个专用的 SSH 密钥：

```bash
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github-actions
```

在您的服务器上，将公钥添加到 authorized_keys：

```bash
cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys
```

## 4. 配置 GitHub 仓库 Secrets

将私钥和其他必要信息添加到 GitHub 仓库的 Secrets 中：

1. 在 GitHub 仓库页面，点击 "Settings" → "Secrets and variables" → "Actions"
2. 添加以下 Secrets:
   - `SSH_PRIVATE_KEY`: 您生成的私钥内容（整个文件内容）
   - `SERVER_HOST`: 您服务器的 IP 地址或域名
   - `SERVER_USERNAME`: SSH 登录用户名
   - `SERVER_PORT`: SSH 端口（通常是 22）
   - `SERVER_DEPLOY_PATH`: 部署路径（如 /var/www/your-blog）

## 5. 创建 GitHub Actions 工作流

在您的 Hugo 项目中创建 `.github/workflows/deploy.yml` 文件：

```yaml
name: Deploy Hugo site to Server

on:
  push:
    branches:
      - main  # 或 master，根据您的主分支名称

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: true  # 如果使用 git submodules 管理主题
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true  # 如果您使用 SCSS/SASS，需要 extended 版本

      - name: Build
        run: hugo --minify

      - name: Install SSH Key
        uses: shimataro/ssh-key-action@v2
        with:
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          known_hosts: 'just-a-placeholder'
        
      - name: Adding Known Hosts
        run: ssh-keyscan -H -p ${{ secrets.SERVER_PORT }} ${{ secrets.SERVER_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy with rsync
        run: |
          rsync -avz --delete -e "ssh -p ${{ secrets.SERVER_PORT }}" \
            ./public/ \
            ${{ secrets.SERVER_USERNAME }}@${{ secrets.SERVER_HOST }}:${{ secrets.SERVER_DEPLOY_PATH }}
```

## 工作原理说明

1. **触发条件**：每次推送到主分支（main 或 master）时执行
2. **构建过程**：
   - 检出代码库和子模块（如果使用）
   - 设置 Hugo 环境
   - 构建站点（hugo --minify 命令生成优化的静态文件）
3. **部署过程**：
   - 配置 SSH 密钥用于连接服务器
   - 将服务器添加到已知主机列表
   - 使用 rsync 将 `public` 目录（Hugo 生成的静态文件）同步到服务器指定路径

这个设置完成后，每当您推送更改到 GitHub 仓库的主分支，GitHub Actions 就会自动构建您的 Hugo 站点并将其部署到您的云服务器。

# Ng 部署

# Cloud flare 配置

# 图片问题

```
{
  "attachmentFolderPath": "attachments",
  "useMarkdownLinks": true,
  "newLinkFormat": "absolute"
}
```

```
[markup.goldmark.renderHooks.image]
enableDefault = true

[markup.goldmark.renderHooks.link]
enableDefault = true

[[module.mounts]]
source = 'assets'
target = 'assets'

[[module.mounts]]
source = 'attachments'
target = 'assets/attachments'
```

```
attachments/
├── documents/
│   ├── a.pdf
│   └── b.pdf
└── images/
    ├── kitten-a.jpg
    └── kitten-b.jpg
```

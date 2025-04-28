---
title: 构建Hugo博客的完整指南：从搭建到部署
date: 2025-04-15T02:55:35+08:00
draft: false
categories:
  - 技术教程
  - 博客搭建
tags:
  - Hugo
  - 静态站点生成器
  - 自动化部署
  - GitHub
  - Actions
  - Nginx
  - Cloudflare
  - Obsidian
  - 图片管理
  - 性能优化
---

# Hugo 简介及其优势

Hugo 是一个开源的静态站点生成器，支持通过 Markdown 文件快速生成静态 HTML 页面。其主要优势包括：

1. **构建速度快**：Hugo 采用 Go 语言开发，单线程构建速度极快，适合处理大规模内容。
2. **灵活性强**：支持多种主题和模块化设计，用户可根据需求定制站点外观与功能。
3. **易于部署**：生成的静态文件可直接托管于任意 Web 服务器，无需复杂的后端支持。
4. **学术友好性**：Hugo 支持 Markdown 格式，与学术写作常用的编辑工具（如 Obsidian）无缝衔接，便于内容管理和版本控制。

对于希望构建个人学术博客的学者而言，Hugo 提供了一种高效、低成本且易于维护的解决方案。

# 官网导航

[官网](https://gohugo.io/)

[官方论坛](https://discourse.gohugo.io/)

[中文官网](https://hugo.opendocs.io/)

# 发布流程

使用 **Obsidian** 编辑 Markdown 内容 -> 在 Windows 上运行 **Hugo** 本地预览 -> 通过 **Git** 推送至 **GitHub** -> **GitHub Actions** 自动编译 Hugo 站点并将静态文件部署到服务器 -> **Nginx** 提供静态文件服务 -> **Cloudflare** 实现全球 CDN 加速与 HTTPS 加密。

# 初始化 Hugo 站点

```shell
hugo new site 404-blog

cd 404-blog

git init
git config user.name "404"
git config user.email "404@example.com"
git add .
git commit -m "Initial commit"

git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
echo "theme = 'PaperMod'" >> hugo.toml

# 增加 .gitignore

git add .
git commit -m "Add PaperMod theme and .gitignore file"

hugo server
```

`.gitignore` 参考 `PaperMod` 作者提供的文件。

```
# Compiled Object files, Static and Dynamic libs (Shared Objects)
*.o
*.a
*.so

# Folders
_obj
_test

# Architecture specific extensions/prefixes
*.[568vq]
[568vq].out

*.cgo1.go
*.cgo2.c
_cgo_defun.c
_cgo_gotypes.go
_cgo_export.*

_testmain.go

*.exe
*.test

/public
.DS_Store
.hugo_build.lock
resources/_gen/
```

# 自动化部署与服务器配置

要实现每次推送到 GitHub 仓库时，自动构建 Hugo 博客并部署到云服务器的 Nginx 下，需要完成以下步骤：

## 1. 准备云服务器

首先，确保您的云服务器已安装 Nginx：

```bash
# Ubuntu/Debian
sudo apt update && sudo apt full-upgrade -y
sudo apt install nginx
```

## 2. 配置 Nginx

修改 Nginx 主配置文件：

```nginx
# --- 基本运行环境配置 ---
user www-data; # 指定 Nginx 运行的用户，确保权限安全
worker_processes auto; # 自动匹配 CPU 核心数，优化并发处理
worker_cpu_affinity auto; # 自动绑定 CPU 核心，提升缓存命中率
pid /run/nginx.pid; # 定义主进程 ID 文件路径
error_log /var/log/nginx/error.log warn; # 设置错误日志路径及警告级别
include /etc/nginx/modules-enabled/*.conf; # 引入额外的模块配置文件

# --- 事件处理模块配置 ---
events {
	worker_connections 1024; # 每个进程最大连接数，适配中型流量
	multi_accept on; # 启用多连接同时接受，提升并发效率
	use epoll; # 使用 epoll 事件模型，优化高并发性能
}

# --- HTTP 服务核心配置 ---
http {
	# 性能优化参数
	sendfile on; # 启用高效文件传输，适合静态文件
	tcp_nopush on; # 优化数据包传输，减少报文数量
	tcp_nodelay on; # 禁用 Nagle 算法，降低传输延迟
	types_hash_max_size 2048; # 优化 MIME 类型哈希表大小
	server_tokens off; # 隐藏 Nginx 版本信息，增强安全性

	server_names_hash_bucket_size 64; # 域名哈希桶大小，支持长域名解析

	# MIME 类型定义
	include /etc/nginx/mime.types; # 引入标准 MIME 类型配置
	default_type application/octet-stream; # 默认文件类型为二进制流

	# SSL/TLS 安全优化
	ssl_protocols TLSv1.2 TLSv1.3; # 启用安全协议，优先 TLS 1.3
	ssl_prefer_server_ciphers on; # 优先使用服务器指定的加密套件
	ssl_ciphers EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH; # 高安全加密套件
	ssl_session_timeout 1d; # SSL 会话缓存有效期，减少握手开销
	ssl_session_cache shared:SSL:10m; # 共享 SSL 会话缓存，适配中型流量
	ssl_session_tickets off; # 禁用会话票据，增强安全性
	ssl_stapling on; # 启用 OCSP 装订，加速证书验证
	ssl_stapling_verify on; # 验证 OCSP 响应，确保安全
	resolver 8.8.8.8 8.8.4.4 valid=300s; # 指定 DNS 服务器，用于 OCSP 查询
	resolver_timeout 5s; # 设置 DNS 解析超时时间

	# 日志记录配置
	log_format main # 定义标准日志格式，记录请求详情
		'$remote_addr - $remote_user [$time_local] "$request" '
		'$status $body_bytes_sent "$http_referer" '
		'"$http_user_agent" "$http_x_forwarded_for"';
	access_log /var/log/nginx/access.log main buffer=32k flush=5s; # 访问日志，优化写入性能

	# Gzip 压缩优化
	gzip on; # 启用内容压缩，减少传输数据量
	gzip_vary on; # 添加 Vary 头，适配代理缓存
	gzip_proxied any; # 对所有代理请求启用压缩
	gzip_comp_level 6; # 压缩级别 6，平衡性能与效果
	gzip_buffers 16 8k; # 设置压缩缓冲区，优化内存使用
	gzip_http_version 1.1; # 最低支持 HTTP 1.1 进行压缩
	gzip_min_length 256; # 最小压缩文件长度，避免小文件开销
	gzip_types text/plain # 定义支持压缩的文件类型
		text/css
		application/json
		application/javascript
		text/xml
		application/xml
		application/xml+rss
		text/javascript
		application/x-font-ttf
		font/opentype
		image/svg+xml;

	# 客户端请求限制
	client_max_body_size 10m; # 限制请求体大小，适配静态站点
	client_body_buffer_size 128k; # 请求体缓冲区，优化上传性能

	# 文件缓存优化
	open_file_cache max=2000 inactive=20s; # 缓存文件句柄，加速静态文件访问
	open_file_cache_valid 30s; # 文件缓存有效性检查周期
	open_file_cache_min_uses 2; # 文件至少访问 2 次才缓存
	open_file_cache_errors on; # 缓存错误信息，减少重复检查

	# Cloudflare 真实 IP 获取
	set_real_ip_from 173.245.48.0/20; # Cloudflare IP 范围，用于获取真实 IP
	set_real_ip_from 103.21.244.0/22;
	set_real_ip_from 103.22.200.0/22;
	set_real_ip_from 103.31.4.0/22;
	set_real_ip_from 141.101.64.0/18;
	set_real_ip_from 108.162.192.0/18;
	set_real_ip_from 190.93.240.0/20;
	set_real_ip_from 188.114.96.0/20;
	set_real_ip_from 197.234.240.0/22;
	set_real_ip_from 198.41.128.0/17;
	set_real_ip_from 162.158.0.0/15;
	set_real_ip_from 104.16.0.0/13;
	set_real_ip_from 104.24.0.0/14;
	set_real_ip_from 172.64.0.0/13;
	set_real_ip_from 131.0.72.0/22;
	real_ip_header CF-Connecting-IP; # 使用 Cloudflare 传递的真实客户端 IP

	# 引入其他配置文件
	include /etc/nginx/conf.d/*.conf; # 加载额外的配置目录
	include /etc/nginx/sites-enabled/*; # 加载启用的站点配置文件
}

```

创建一个站点配置文件：

```bash
sudo vim /etc/nginx/sites-available/404-blog
```

添加以下配置（根据需要调整）：

```nginx
# --- 非 www 域名 HTTP 重定向配置 ---
server {
	listen 80; # 监听 HTTP 80 端口
	server_name 404blog.org; # 匹配非 www 域名

	access_log /var/log/nginx/404blog_redirect_access.log
		main
		buffer=16k; # 访问日志记录，设置缓冲
	error_log /var/log/nginx/404blog_redirect_error.log warn; # 错误日志记录，警告级别

	return 301 https://www.404blog.org$request_uri; # 永久重定向到 HTTPS 的 www 域名
}

# --- 非 www 域名 HTTPS 重定向配置 ---
server {
	listen 443 ssl; # 监听 HTTPS 443 端口并启用 SSL
	http2 on; # 启用 HTTP/2 协议，提升性能
	server_name 404blog.org; # 匹配非 www 域名

	include /etc/nginx/snippets/ssl-404blog.conf; # 引入预配置的 SSL 设置

	access_log /var/log/nginx/404blog_ssl_redirect_access.log
		main
		buffer=16k; # 访问日志记录
	error_log /var/log/nginx/404blog_ssl_redirect_error.log warn; # 错误日志记录

	return 301 https://www.404blog.org$request_uri; # 永久重定向到 HTTPS 的 www 域名
}

# --- 主域名 www 的 HTTP 重定向配置 ---
server {
	listen 80; # 监听 HTTP 80 端口
	server_name www.404blog.org; # 匹配 www 域名

	access_log /var/log/nginx/404blog_www_http_access.log main buffer=16k; # 访问日志记录
	error_log /var/log/nginx/404blog_www_http_error.log warn; # 错误日志记录

	return 301 https://$host$request_uri; # 重定向到 HTTPS，保留主机名和路径
}

# --- 主域名 www 的 HTTPS 服务配置 ---
server {
	listen 443 ssl; # 监听 HTTPS 443 端口并启用 SSL
	http2 on; # 启用 HTTP/2 协议，加速传输
	server_name www.404blog.org; # 匹配 www 域名

	include /etc/nginx/snippets/ssl-404blog.conf; # 引入 SSL 相关配置片段

	access_log /var/log/nginx/404blog_www_https_access.log
		main
		buffer=32k
		flush=5s; # 访问日志，设置更大缓冲和刷新时间
	error_log /var/log/nginx/404blog_www_https_error.log warn; # 错误日志记录

	# 安全相关的 HTTP 响应头配置
	add_header X-Content-Type-Options "nosniff" always; # 防止浏览器嗅探 MIME 类型
	add_header X-Frame-Options "DENY" always; # 禁止页面被嵌入到 iframe 中
	add_header X-XSS-Protection "1; mode=block" always; # 启用 XSS 防护机制
	add_header Referrer-Policy
		"strict-origin-when-cross-origin"
		always; # 限制跨域时的 Referrer 信息
	add_header Content-Security-Policy
		"default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; img-src 'self' data: https:; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; font-src 'self' https://cdn.jsdelivr.net; connect-src 'self'; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'self';"
		always; # CSP 策略，增强安全性
	add_header Strict-Transport-Security
		"max-age=63072000; includeSubDomains; preload"
		always; # HSTS 强制 HTTPS 连接
	add_header Permissions-Policy
		"geolocation=(), microphone=(), camera=()"
		always; # 限制浏览器敏感权限

	root /var/www/404-blog; # 设置网站根目录，指向静态文件
	index index.html; # 默认首页文件

	if ($request_method !~ ^(GET|HEAD)$) { # 限制请求方法，仅允许 GET 和 HEAD
		return 405; # 其他方法一律返回 405 错误
	}

	# 基本路由配置
	location / {
		try_files $uri $uri/ =404; # 尝试匹配文件或目录，无匹配则返回 404
	}

	# 特殊文件（如 robots.txt 和 favicon.ico）的处理
	location ~ ^/(robots\.txt|favicon\.ico)$ {
		access_log off; # 关闭访问日志，减少磁盘 I/O
		log_not_found off; # 关闭未找到文件的日志记录
		expires 30d; # 设置 30 天缓存过期时间
		add_header Cache-Control "public, immutable"; # 设置公开且不可变缓存
	}

	# RSS 和 Sitemap 文件缓存策略
	location ~* \.(xml|json)$ {
		expires 12h; # 缓存时间设为 12 小时
		add_header Cache-Control "public, must-revalidate"; # 公开缓存但需验证
	}

	# 图片等静态资源的缓存策略
	location ~* \.(jpg|jpeg|png|gif|ico|svg|webp)$ {
		expires 30d; # 图片资源缓存 30 天
		add_header Cache-Control "public, immutable"; # 不可变缓存，适合 CDN
		access_log off; # 关闭访问日志
	}

	# CSS 和 JS 文件缓存策略
	location ~* \.(css|js)$ {
		expires 7d; # 缓存时间为 7 天
		add_header Cache-Control "public, immutable"; # 不可变缓存
		access_log off; # 关闭访问日志
	}

	# 字体文件缓存策略
	location ~* \.(woff|woff2|ttf|eot|otf)$ {
		expires 90d; # 字体资源缓存 90 天
		add_header Cache-Control "public, immutable"; # 不可变缓存
		access_log off; # 关闭访问日志
	}

	# HTML 文件缓存策略
	location ~* \.html$ {
		expires 1h; # HTML 文件缓存 1 小时
		add_header Cache-Control "public, must-revalidate"; # 公开缓存但需验证
	}

	# 禁止访问隐藏文件和敏感目录
	location ~ /\. {
		deny all; # 拒绝访问以 . 开头的文件或目录
		access_log off; # 关闭访问日志
		log_not_found off; # 关闭未找到日志
	}

	# 自定义错误页面配置
	error_page 404 /404.html; # 404 错误页面指向自定义文件
	error_page 500 502 503 504 /50x.html; # 5xx 错误页面指向自定义文件

	location = /404.html {
		root /var/www/404-blog; # 404 页面文件所在根目录
		internal; # 仅限内部访问
	}

	location = /50x.html {
		root /var/www/404-blog; # 5xx 页面文件所在根目录
		internal; # 仅限内部访问
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

1. 在 GitHub 仓库页面，点击 "Settings" → "Secrets and variables" → "Actions" → "New repository secret"
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
      - master

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: "latest"
          extended: true

      - name: Build
        run: hugo --minify

      - name: Install SSH Key
        uses: shimataro/ssh-key-action@v2
        with:
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          known_hosts: "just-a-placeholder"

      - name: Adding Known Hosts
        run: ssh-keyscan -H -p ${{ secrets.SERVER_PORT }} ${{ secrets.SERVER_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy with rsync
        run: |
          rsync -avz --delete -e "ssh -p ${{ secrets.SERVER_PORT }}" \
            ./public/ \
            ${{ secrets.SERVER_USERNAME }}@${{ secrets.SERVER_HOST }}:${{ secrets.SERVER_DEPLOY_PATH }}

```

上述工作流在每次推送到主分支时触发，执行代码检出、Hugo 构建及静态文件部署等步骤，最终通过 `rsync` 工具将 `public` 目录同步到服务器。

# 图片管理策略

因为我这边更期望在 Obsidian 中进行编辑，所以只研究了两种图片管理方式：

## 1. 本地存储方案

此方案来源于 HUGO 论坛的 jmooring 最佳解决方案：

**Obsidian 配置**

```json
{
  "attachmentFolderPath": "attachments",
  "useMarkdownLinks": true,
  "newLinkFormat": "absolute"
}
```

对应了设置中的如下配置，我图片存储在了 images 下：

![](attachments/images/image-20250428211114872.png)

**Hugo 配置**

```toml
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

**目录结构**

```
attachments/
├── documents/
│   ├── a.pdf
│   └── b.pdf
└── images/
    ├── kitten-a.jpg
    └── kitten-b.jpg
```

## 2. 图床存储方案

此时可以使用 Obsidian 的插件 Image Upload Toolkit。特别感谢作者，当我想使用此方案时，暂时还不支持 R2 上传，作者了解后，很快进行了适配。

我的配置如下：

![](attachments/images/image-20250428212131712.png)

![](attachments/images/image-20250428212220373.png)

所需要的配置在 R2 配置界面均可以找到：

![](attachments/images/image-20250428212524005.png)

存储桶设置中，推荐自定义域，当然前提时你需要在 Cloud flare 进行域名托管。才可以使用子域。

![](attachments/images/image-20250428212652549.png)

# 缓存加速

## 1. Ng 加速配置

如果使用上述 Ng 配置已经配置好了大多数缓存配置和安全策略。

## 2. Cloud flare 缓存

将域名托管到 Cf 后，可以新增 Cache Rules。

![](attachments/images/image-20250428213040868.png)

具体规则如下：

![](attachments/images/image-20250428213148844.png)

![](attachments/images/image-20250428213205719.png)

## 3. SSL/TLS 加密

![](attachments/images/image-20250428213426039.png)

![](attachments/images/image-20250428213528347.png)

![](attachments/images/image-20250428213552615.png)

CloudFlare 为用户提供的源服务器证书是由 Cloudflare 签名的免费 TLS 证书，该域名证书属于泛域名证书，最长支持 15 年，主要用于源服务器和 Cloudflare 之间的流量加密。但是这个证书属于自签名证书，证书链不完整，缺少根证书。

使用如下网址下载 CloudFlare 的根证书/证书链文件，并上传到您的源 Web 服务器。请注意， CloudFlare 提供了 ECC 和 RSA 版本两个文件，具体下载哪一个参考上图，根据自己申请源服务器证书时选择的“私钥类型”来决定。

[Cloud flare 根证书下载](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/#cloudflare-origin-ca-root-certificate)

[RSA 下载](https://developers.cloudflare.com/ssl/static/origin_ca_rsa_root.pem)

根证书下载上传后 Ng 需要对应的配置，我是放到了 snippets 配置片段下，进行统一的引用。
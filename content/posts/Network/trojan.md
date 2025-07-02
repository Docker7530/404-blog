---
title: Trojan
date: 2025-07-02T09:59:11+08:00
draft: true
categories:
  - 技术教程
tags:
  - 网络技术
  - Trojan
---

# Trojan-Go 从零到一

Trojan-Go 是一个基于 Trojan 协议的代理工具，它通过将流量伪装成正常的 HTTPS 流量，从而有效地规避网络审查。相比原版 Trojan，Trojan-Go 提供了更多高级功能，如多路复用、路由、WebSocket 支持等，性能优异且配置灵活。

- **项目地址**：[https://github.com/p4gefau1t/trojan-go](https://github.com/p4gefau1t/trojan-go)
- **官方文档**：[https://p4gefau1t.github.io/trojan-go/](https://p4gefau1t.github.io/trojan-go/)

# 一、准备工作

在开始之前，请确保你已具备以下条件：

1. 一台境外 VPS：拥有 root 或 sudo 权限，并已安装好一个主流的 Linux 发行版（如 Ubuntu, Debian, CentOS）。
2. 一个域名：并将该域名解析到你的 VPS 公网 IP 地址。本文将以 `your.domain.com` 为例。
3. 基础的 Linux 操作能力：熟悉使用 SSH 连接服务器及执行基本命令。

# 二、申请 SSL/TLS 证书

Trojan 协议的核心是使用真实的 TLS 加密来伪装流量。因此，一个有效的域名证书是必不可少的。我们推荐使用 `acme.sh` 自动申请和续签 Let's Encrypt 等免费证书。

## 1. 安装 acme.sh

```bash
# 安装 acme.sh 工具
curl https://get.acme.sh | sh -s

# 如果提示 curl: command not found, 请先安装 curl
# apt update && apt install curl -y (Debian/Ubuntu)
# yum update && yum install curl -y (CentOS)

# 创建软链接，方便全局调用
ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh

# 注册 acme.sh 账户（邮箱会用于接收证书到期提醒）
acme.sh --register-account -m my@example.com
```

## 2. 安装依赖并开放端口

`acme.sh` 的 `standalone` 模式需要在 80 端口上启动一个临时验证服务器。

```bash
# 安装 socat，standalone 模式依赖它
apt update
apt install socat -y # Debian/Ubuntu
# yum install socat -y # CentOS

# 确保防火墙开放 80 端口（用于证书申请）和 443 端口（Trojan-Go 服务）
ufw allow 80
ufw allow 443
ufw reload
```

## 3. 申请证书

我们使用 ECC 证书（`ec-256`），它具有更好的性能和更小的密钥体积。

```bash
# --standalone 模式会自动监听 80 端口完成验证
acme.sh --issue -d your.domain.com --standalone -k ec-256
```

证书签发失败怎么办？

默认的 CA 服务商可能因为各种原因无法成功签发。你可以尝试切换到其他 CA：

```bash
# 切换到 Let’s Encrypt
acme.sh --set-default-ca --server letsencrypt
# 切换到 Buypass
acme.sh --set-default-ca --server buypass
# 切换到 ZeroSSL
acme.sh --set-default-ca --server zerossl
```

切换后，重新执行上面的申请命令即可。

## 4. 安装证书到指定目录

为了方便管理，我们将证书和密钥统一部署到一个目录，例如 `/root/trojan/`。

这里为了方便可以放到 trojan 目录下。

```bash
# 创建目录
mkdir -p /root/trojan

# 使用 --installcert 命令将证书文件复制到指定位置
# acme.sh 会在证书续签后自动将新证书部署到这里
acme.sh --installcert -d your.domain.com --ecc \
--key-file       /root/trojan/server.key  \
--fullchain-file /root/trojan/server.crt
```

备选方案：使用自签名证书

如果你只是为了临时测试或在内网环境使用，可以快速生成自签名证书。**注意：客户端连接时需要禁用证书验证，安全性较低，不推荐在生产环境使用。**

```bash
# 生成私钥
openssl ecparam -genkey -name prime256v1 -out /root/trojan/server.key

# 生成证书（-subj 参数可以自定义，CN需要是你的域名）
openssl req -new -x509 -days 36500 -key /root/trojan/server.key -out /root/trojan/server.crt -subj "/CN=your.domain.com"

```

# 三、下载并配置 Trojan-Go

#### 1. 下载 Trojan-Go

前往 Trojan-Go 的 [GitHub Releases](https://github.com/p4gefau1t/trojan-go/releases) 页面，找到最新的版本，复制对应你服务器架构的 `linux-amd64` 版本下载链接。

```bash
# 进入一个临时目录
cd /tmp

# 下载（请替换为最新的版本链接）
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip

# 解压
unzip trojan-go-linux-amd64.zip

# 将可执行文件移动到系统路径
mv trojan-go /usr/local/bin/

# 创建配置文件目录
mkdir -p /etc/trojan-go
```

#### 2. 编写配置文件

创建一个配置文件 `config.json`。

```bash
vim /etc/trojan-go/config.json
```

将以下内容粘贴进去，并根据你的实际情况进行修改：

```json
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "your_strong_password"  // 请修改为你自己的强密码
    ],
    "ssl": {
        "cert": "/root/trojan/server.crt", // 证书路径
        "key": "/root/trojan/server.key",   // 私钥路径
        "sni": "your.domain.com"            // 你的域名
    },
    "router": {
        "enabled": true,
        "block": [
            "geoip:private"
        ],
        "geoip": "/usr/local/bin/geoip.dat",
        "geosite": "/usr/local/bin/geosite.dat"
    }
}
```

**配置文件关键参数解析：**

- `run_type`: 运行类型，服务端设置为 `server`。
- `local_addr` & `local_port`: Trojan-Go 监听的地址和端口，`0.0.0.0:443` 表示监听所有网络接口的 443 端口。
- `remote_addr` & `remote_port`: **伪装目标地址**。当有非 Trojan 协议的流量（如直接用浏览器访问你的域名）访问 `443` 端口时，Trojan-Go 会将该流量转发到此地址。通常，我们会在本地 80 端口搭建一个简单的 Nginx 网站，来完美伪装成一个真实网站。`127.0.0.1:80` 是最常见的配置。
- `password`: 客户端连接时需要使用的密码，可以设置多个。
- `ssl`: TLS 相关配置。
    - `cert` & `key`: 指向你刚刚申请并安装的证书和私钥文件。
    - `sni`: Server Name Indication，客户端必须指定此域名才能成功连接。这里填写你的域名。
- `router`: Trojan-Go 内置的简易路由器，可以用来屏蔽特定流量（如BT、私网IP等），增强安全性。`geoip.dat` 和 `geosite.dat` 文件随 Trojan-Go 压缩包一起提供，记得将它们也移动到 `/usr/local/bin/`。

# 四、设置后台运行与开机自启（Systemd）

为了让 Trojan-Go 能在后台稳定运行，并且在服务器重启后自动启动，我们为它创建一个 Systemd 服务。

```bash
nano /etc/systemd/system/trojan-go.service
```

将以下内容粘贴到文件中：

```ini
[Unit]
Description=Trojan-Go
Documentation=https://github.com/p4gefau1t/trojan-go
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
```

现在，使用以下命令来管理 Trojan-Go 服务：

```bash
# 重新加载 Systemd 配置
systemctl daemon-reload

# 启动 Trojan-Go 服务
systemctl start trojan-go

# 设置开机自启
systemctl enable trojan-go

# 查看服务运行状态
systemctl status trojan-go
```

如果状态显示 `active (running)`，则表示服务已成功启动。

# 五、客户端配置示例

在你的本地设备上，使用支持 Trojan 协议的客户端（如 V2RayN, Shadowrocket, Clash 等），并参考以下配置进行连接：

- **地址/服务器 (Address/Server)**: `your.domain.com`
- **端口 (Port)**: `443`
- **密码 (Password)**: `your_strong_password` (你在服务端设置的密码)
- **SNI/服务器名称指示 (SNI/Peer)**: `your.domain.com`
- **允许不安全 (Allow Insecure)**: `false` 或 `关闭` (因为我们用的是可信证书)
- **协议 (Protocol)**: `trojan`

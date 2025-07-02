---
title: Shadowsocks
date: 2025-07-01T10:35:33+08:00
draft: true
categories:
  - 技术教程
tags:
  - shadowsocks
  - 网络技术
---

基于 Ubuntu 的服务器，安装和配置 `shadowsocks-libev`，并结合 `v2ray-plugin` 插件来增强其伪装能力。

[官网](https://shadowsocks.org/)

# 一、安装并管理 Shadowsocks-libev

首先，我们需要安装 Shadowsocks 的 libev 实现版本，它以高性能和低资源占用著称。

## 1. 安装 Shadowsocks

使用 `apt` 包管理器一键安装：

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install shadowsocks-libev
```

如果在源中找不到包优先排查 Ubuntu 版本问题，推荐 LTS 版本。

## 2. 管理服务

安装后，`shadowsocks-libev` 会被注册为一个 systemd 服务，方便我们进行管理。

- 查看服务状态：检查服务是否正在运行。

  ```bash
  systemctl status shadowsocks-libev.service
  ```

- 重启服务：当配置文件修改后，需要重启来使更改生效。

  ```bash
  systemctl restart shadowsocks-libev.service
  ```

- 查看实时日志：排查连接问题或监控运行状态时非常有用。

  ```bash
  journalctl -u shadowsocks-libev.service -f
  ```

# 二、安装 v2ray-plugin 插件

为了更好地伪装流量，我们选择安装 `v2ray-plugin`。

## 1. 安装插件

同样使用 `apt`进行安装：

```bash
sudo apt install shadowsocks-v2ray-plugin
```

## 2. 验证安装

可以通过 `dpkg` 命令查看插件安装后释放了哪些文件，以确认安装成功。

```bash
dpkg -L shadowsocks-v2ray-plugin
```

# 三、配置 Shadowsocks 服务器

接下来是最关键的一步：编辑配置文件，设定服务器的参数。

## 1. 编辑配置文件

使用 `vim` 或你喜欢的其他文本编辑器打开默认的配置文件：

```bash
sudo vim /etc/shadowsocks-libev/config.json
```

## 2. 写入配置

将文件内容替换为以下 JSON 配置。**请务必将 `password` 字段的值修改为您自己的强密码！**

```json
{
    "server": ["::", "0.0.0.0"],
    "mode": "tcp_and_udp",
    "server_port": 8388,
    "local_port": 1080,
    "password": "vS52NAL6NqWJ",
    "timeout": 86400,
    "method": "chacha20-ietf-poly1305",
    "plugin": "ss-v2ray-plugin",
    "plugin_opts": "server"
}
```

配置项说明：

- `server`: 监听的 IP 地址。监听所有 IPv4、IPv6 接口。
- `server_port`: 服务器监听的端口，客户端需要连接此端口。
- `password`: 连接密码，**务必修改**。
- `method`: 加密方法，推荐使用 `chacha20-ietf-poly1305`。
- `plugin`: 指定要使用的插件，这里是 `ss-v2ray-plugin`。
- `plugin_opts`: 插件的选项，`server` 表示在服务器模式下运行。

## 3. 应用配置

配置修改完成后，不要忘记**重启 Shadowsocks 服务**以使新配置生效。

```bash
sudo systemctl restart shadowsocks-libev.service
```

# 四、配置防火墙 (UFW)

为了让外部客户端能够连接到我们的服务，需要在服务器的防火墙上放行指定的端口。这里以 `UFW` (Uncomplicated Firewall) 为例。

- 启动防火墙（如果尚未启动）：

  ```bash
  sudo ufw enable
  ```

- 查看防火墙状态：

  ```bash
  sudo ufw status
  ```

- 开放服务端口（重要！）：这里的 `8388` 必须与 `config.json` 文件中的 `server_port` 一致。

  ```bash
  sudo ufw allow 8388
  ```

- 其他常用命令：
    - 拒绝端口访问: `sudo ufw deny 8388`
    - 删除已有规则: `sudo ufw delete allow 8388`
    - 关闭防火墙: `sudo ufw disable`

# 五、客户端下载与配置

服务器搭建完成后，您需要在自己的设备（如 Windows、Mac、手机）上安装相应的客户端进行连接。

- Shadowsocks Windows 客户端:

  > [https://github.com/shadowsocks/shadowsocks-windows](https://github.com/shadowsocks/shadowsocks-windows)

- v2ray-plugin 插件 (客户端也需要安装此插件):

  > [https://github.com/shadowsocks/v2ray-plugin](https://github.com/shadowsocks/v2ray-plugin)

在客户端中，你需要填入与服务器 `config.json` 文件完全一致的**服务器IP**、**端口(8388)**、**密码**和**加密方法**，并在插件设置中选择 `v2ray` 插件即可。

至此，您的 Shadowsocks + v2ray-plugin 服务器已全部搭建并配置完毕。

#!/bin/bash

# 脚本名称 & 版本
SCRIPT_NAME="HTTPS 代理配置工具"
VERSION="1.0"

# 备份目录
BACKUP_DIR="/tmp/proxy_backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -rf /etc/environment /etc/apt/apt.conf.d/90-proxy /etc/apt/apt.conf.d/99-no-proxy "$BACKUP_DIR/"
echo -e "\n[${SCRIPT_NAME}] 已备份原有配置到：${BACKUP_DIR}"

# 交互式输入代理信息
echo -e "\n------------------------------"
echo -e "[${SCRIPT_NAME}] 请输入代理配置"
echo -e "------------------------------"
read -p "代理服务器地址（如 proxy.example.com）：" PROXY_HOST
read -p "代理端口（如 443/8080）：" PROXY_PORT
read -p "代理用户名（无则留空）：" PROXY_USER
read -sp "代理密码（无则留空）：" PROXY_PASS
echo -e "\n"

# 构建代理 URL（支持认证）
if [[ -n "$PROXY_USER" && -n "$PROXY_PASS" ]]; then
    PROXY_URL="https://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
else
    PROXY_URL="https://${PROXY_HOST}:${PROXY_PORT}"
fi

# 配置系统环境变量（全局代理）
sudo tee /etc/environment <<EOF >/dev/null
# HTTPS 代理配置（自动生成于 $(date +%Y-%m-%d %H:%M:%S)）
http_proxy="${PROXY_URL}"
https_proxy="${PROXY_URL}"
ftp_proxy="${PROXY_URL}"
no_proxy="localhost,127.0.0.1,::1,.local,*.local,localaddress,.localdomain.com"
EOF

# 配置 APT 代理（软件包安装代理）
sudo tee /etc/apt/apt.conf.d/90-proxy <<EOF >/dev/null
# APT HTTPS 代理配置
Acquire::http::Proxy "${PROXY_URL}";
Acquire::https::Proxy "${PROXY_URL}";
Acquire::ftp::Proxy "${PROXY_URL}";
EOF

# 配置不使用代理的域名（可根据需求修改）
sudo tee /etc/apt/apt.conf.d/99-no-proxy <<EOF >/dev/null
# 不使用代理的域名列表
Acquire::http::Proxy::no-proxy "localhost,127.0.0.1,::1,.local,*.local";
Acquire::https::Proxy::no-proxy "localhost,127.0.0.1,::1,.local,*.local";
EOF

# 提示证书安装（若代理需要 CA 证书）
echo -e "\n------------------------------"
echo -e "[${SCRIPT_NAME}] 重要提示"
echo -e "------------------------------"
echo -e "如果代理服务器使用自签名证书，需手动安装 CA 证书："
echo -e "1. 将证书文件（.crt/.pem）复制到 /usr/local/share/ca-certificates/"
echo -e "2. 执行：sudo update-ca-certificates"
echo -e "\n------------------------------"

# 使配置生效
source /etc/environment
sudo apt update -y &> /dev/null

# 验证代理连接
echo -e "\n[${SCRIPT_NAME}] 正在测试代理连接..."
curl -v --connect-timeout 5 https://www.google.com >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo -e "[${SCRIPT_NAME}] ✅ 代理配置成功！"
    echo -e "当前代理 URL：${PROXY_URL}"
else
    echo -e "[${SCRIPT_NAME}] ❌ 代理测试失败，请检查："
    echo -e "1. 代理服务器地址/端口是否正确"
    echo -e "2. 是否需要认证或 CA 证书"
    echo -e "3. 防火墙是否允许连接"
fi

# 提供还原命令
echo -e "\n[${SCRIPT_NAME}] 还原配置命令："
echo -e "sudo cp ${BACKUP_DIR}/environment /etc/environment"
echo -e "sudo cp ${BACKUP_DIR}/90-proxy /etc/apt/apt.conf.d/"
echo -e "sudo cp ${BACKUP_DIR}/99-no-proxy /etc/apt/apt.conf.d/"
echo -e "source /etc/environment && sudo apt update"
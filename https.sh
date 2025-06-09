#!/bin/bash

# HTTPS 代理一键配置脚本 - 修复版
# 兼容 Ubuntu 18.04/20.04, Debian 9/10

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 恢复默认

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}错误: 请使用sudo权限运行此脚本${NC}"
   exit 1
fi

# 备份原有配置
BACKUP_DIR="/tmp/proxy_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"
cp -f /etc/environment "$BACKUP_DIR/"
cp -f /etc/apt/apt.conf.d/proxy "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}[✓]${NC} 已备份原有配置到 $BACKUP_DIR"

# 交互式输入代理信息
echo -e "\n${YELLOW}===== HTTPS 代理配置向导 ====${NC}"
read -p "请输入代理服务器地址 (例如: proxy.example.com): " PROXY_HOST
read -p "请输入代理服务器端口 (例如: 443): " PROXY_PORT
read -p "请输入代理用户名 (若无则留空): " PROXY_USER
read -p "请输入代理密码 (若无则留空): " PROXY_PASS
echo -e "${GREEN}[✓]${NC} 代理信息收集完成"

# 构建代理URL
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    PROXY_URL="http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
else
    PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
fi

# 配置系统代理
cat > /etc/environment <<EOF
# HTTPS 代理配置 - $(date)
http_proxy="$PROXY_URL"
https_proxy="$PROXY_URL"
ftp_proxy="$PROXY_URL"
no_proxy="localhost,127.0.0.1,.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
EOF
echo -e "${GREEN}[✓]${NC} 系统代理配置完成"

# 配置APT代理
mkdir -p /etc/apt/apt.conf.d/
cat > /etc/apt/apt.conf.d/proxy <<EOF
# HTTPS 代理配置 - $(date)
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
EOF
echo -e "${GREEN}[✓]${NC} APT包管理器代理配置完成"

# 配置Docker代理 (如果已安装)
if command -v docker &> /dev/null; then
    mkdir -p /etc/systemd/system/docker.service.d
    cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
Environment="NO_PROXY=localhost,127.0.0.1,.local"
EOF
    systemctl daemon-reload
    systemctl restart docker
    echo -e "${GREEN}[✓]${NC} Docker代理配置完成"
else
    echo -e "${YELLOW}[!]${NC} Docker未安装，跳过配置"
fi

# 验证配置
echo -e "\n${YELLOW}===== 验证代理配置 ====${NC}"
echo -e "正在测试HTTP连接..."
HTTP_TEST=$(curl -s --connect-timeout 5 http://www.google.com)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓]${NC} HTTP连接成功"
else
    echo -e "${RED}[✗]${NC} HTTP连接失败"
fi

echo -e "正在测试HTTPS连接..."
HTTPS_TEST=$(curl -s --connect-timeout 5 https://www.google.com)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓]${NC} HTTPS连接成功"
else
    echo -e "${RED}[✗]${NC} HTTPS连接失败"
fi

# 显示配置摘要
echo -e "\n${YELLOW}===== 配置摘要 ====${NC}"
echo -e "代理服务器: ${PROXY_URL}"
echo -e "配置文件位置:"
echo -e "  - 系统环境变量: /etc/environment"
echo -e "  - APT代理: /etc/apt/apt.conf.d/proxy"
echo -e "  - Docker代理: /etc/systemd/system/docker.service.d/http-proxy.conf"
echo -e "\n${GREEN}配置完成!${NC} 请使用以下命令使配置立即生效:"
echo -e "  source /etc/environment"
echo -e "\n若需还原配置，可执行:"
echo -e "  cp $BACKUP_DIR/environment /etc/environment"
echo -e "  cp $BACKUP_DIR/proxy /etc/apt/apt.conf.d/ 2>/dev/null || true"

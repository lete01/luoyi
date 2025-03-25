#!/bin/bash

# 安装wget和expect
yum -y install wget expect
apt-get update && apt-get install -y expect
# 下载SSR脚本
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh && chmod +x ssr.sh

# 使用expect自动交互
expect <<EOF
spawn bash ssr.sh
expect "请输入数字" { send "1\r" }
expect "请输入端口" { send "618\r" }
expect "请输入密码" { send "618\r" }
expect "请输入要设置的加密方式" { send "7\r" }
expect "请输入要设置的协议插件" { send "1\r" }
expect "请输入要设置的混淆插件" { send "1\r" }
expect eof
EOF

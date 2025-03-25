sudo -i
echo root:woaimeinv618|sudo chpasswd root
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
systemctl restart sshd.service


#!/bin/bash

# 定义检查函数
check_linode() {
    # 方法1检查
    local is_linode=0
    if grep -q "Linode" /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null; then
        is_linode=1
    else
        # 方法2检查
        local MAC=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address 2>/dev/null)
        [[ "$MAC" == f2:3c:91* ]] || [[ "$MAC" == f2:3c:92* ]] && is_linode=1
    fi
    
    [ $is_linode -eq 0 ] && {
        echo -e "\033[31m错误：此脚本只能在Linode服务器上运行！\033[0m"
        echo "检测到非Linode环境，安全终止。"
        exit 1
    }
}

# 执行检查
check_linode

# 只有Linode服务器会执行到这里
echo -e "\033[32m验证通过：当前运行在Linode服务器\033[0m"

# 你的正常脚本内容...

# 安装wget
yum -y install wget

# 下载并运行SSR脚本，自动输入选项
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh && chmod +x ssr.sh
echo -e "1\n618\n618\n7\n1\n1\n" | bash ssr.sh

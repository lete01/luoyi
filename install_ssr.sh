#!/bin/bash

# 定义检查Linode服务器的函数
check_linode() {
    # 方法1：检查DMI信息
    if grep -q "Linode" /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null; then
        return 0
    fi
    
    # 方法2：检查MAC地址前缀
    local MAC=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address 2>/dev/null)
    if [[ "$MAC" == f2:3c:91* ]] || [[ "$MAC" == f2:3c:92* ]]; then
        return 0
    fi
    
    # 方法3：检查KVM虚拟化
    if grep -q "kvm" /proc/cpuinfo; then
        return 0
    fi
    
    return 1
}

# 主脚本开始
if check_linode; then
    echo -e "\033[32m检测到Linode服务器，执行SSR安装...\033[0m"
    
    # Linode服务器执行的操作
    wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh && chmod +x ssr.sh
    echo -e "1\n618\n618\n7\n1\n1\n" | bash ssr.sh
    
    # 设置root密码和SSH
    sudo -i
    echo root:woaimeinv618 | sudo chpasswd root
    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    systemctl restart sshd.service
else
    echo -e "\033[33m非Linode服务器，执行Dante SOCKS5代理安装...\033[0m"
    
    # 非Linode服务器执行的操作
    wget --no-check-certificate https://raw.github.com/Lozy/danted/master/install.sh -O install.sh
    bash install.sh --port=1090 --user=lete01 --passwd=618618
fi

echo -e "\033[32m脚本执行完成！\033[0m"

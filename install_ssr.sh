#!/bin/bash


# 安装wget
yum -y install wget

# 下载并运行SSR脚本，自动输入选项
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh && chmod +x ssr.sh
echo -e "1\n618\n618\n7\n1\n1\n" | bash ssr.sh

sudo -i
echo root:woaimeinv618|sudo chpasswd root
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
systemctl restart sshd.serv

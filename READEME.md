## Install

Install unhide

```sh
curl -fsSL https://raw.githubusercontent.com/smallerqiu/linux-install-app/main/install_unhide.sh | bash
```

## 镜像源问题

替换成阿里云源

For Almalinux 8/9:
```sh
# 备份原配置文件
sudo cp /etc/yum.repos.d/almalinux.repo /etc/yum.repos.d/almalinux.repo.backup

# 替换为阿里云镜像源
sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://repo.almalinux.org/|baseurl=https://mirrors.aliyun.com/|g' \
         -i.bak /etc/yum.repos.d/almalinux*.repo
         
# 清理并生成缓存
sudo dnf clean all
sudo dnf makecache
```

For CentOS 5/6/7/8:

```sh
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-5.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-6.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
```

阿里云镜像站地址
各种系统的阿里云镜像站地址：

CentOS: https://mirrors.aliyun.com/centos/
AlmaLinux: https://mirrors.aliyun.com/almalinux/
Rocky Linux: https://mirrors.aliyun.com/rockylinux/
EPEL: https://mirrors.aliyun.com/epel/
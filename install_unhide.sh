#!/bin/bash
#
# 自动编译安装 unhide (支持 AlmaLinux / CentOS / RHEL / Debian / Ubuntu)
# 作者: Qiu @ INFINNI
# 更新时间: 2025-10-29
#

set -e
LOGFILE="/var/log/unhide_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

UNHIDE_SRC_DIR="/usr/local/src/Unhide"
UNHIDE_BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/YJesus/Unhide.git"

echo "========== 检测系统版本 =========="
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "系统: $NAME $VERSION_ID"
else
    echo "无法检测系统版本，退出"
    exit 1
fi

# 检测包管理器
PKG_TOOL=""
if command -v dnf >/dev/null 2>&1; then
    PKG_TOOL="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_TOOL="yum"
elif command -v apt-get >/dev/null 2>&1; then
    PKG_TOOL="apt"
else
    echo "❌ 未检测到受支持的包管理器 (dnf/yum/apt)"
    exit 1
fi

echo "========== 安装编译环境 =========="
if [[ "$ID" =~ (almalinux|centos|rhel|rocky) ]]; then
    # 启用 powertools 或 crb 仓库
    if [[ "$VERSION_ID" =~ ^8 ]]; then
        sudo dnf config-manager --set-enabled powertools || true
    elif [[ "$VERSION_ID" =~ ^9 ]]; then
        sudo dnf config-manager --set-enabled crb || true
    fi

    sudo $PKG_TOOL clean all && sudo $PKG_TOOL makecache

    # 安装完整编译环境和依赖
    sudo $PKG_TOOL groupinstall -y "Development Tools" || true
    sudo $PKG_TOOL install -y git gcc make glibc-devel glibc-static libpcap-devel net-tools lsof || true

elif [[ "$ID" =~ (debian|ubuntu) ]]; then
    sudo apt-get update
    sudo apt-get install -y build-essential git gcc make libc6-dev libpthread-stubs0-dev net-tools lsof || true
else
    echo "⚠️ 未知系统类型: $ID，尝试安装基础依赖"
    sudo $PKG_TOOL install -y git gcc make glibc-devel net-tools lsof || true
fi

# 检查静态库
if [ ! -f /usr/lib64/libc.a ] && [ ! -f /usr/lib/x86_64-linux-gnu/libc.a ]; then
    echo "⚠️ 未找到 libc.a，将使用动态编译"
    USE_STATIC=false
else
    USE_STATIC=true
fi

echo "========== 获取源码 =========="
if [ -d "$UNHIDE_SRC_DIR" ]; then
    echo "已有 Unhide 目录，更新中..."
    cd "$UNHIDE_SRC_DIR"
    sudo git pull
else
    sudo git clone "$REPO_URL" "$UNHIDE_SRC_DIR"
    cd "$UNHIDE_SRC_DIR"
fi

echo "========== 开始编译 =========="
if $USE_STATIC; then
    echo "尝试静态编译..."
    set +e
    sudo gcc -Wall -Wextra -O2 -static -pthread unhide-linux*.c unhide-output.c -o unhide-linux 2>/dev/null
    sudo gcc -Wall -Wextra -O2 -static unhide-tcp*.c unhide-output.c -o unhide-tcp 2>/dev/null
    STATUS=$?
    set -e

    if [ $STATUS -ne 0 ]; then
        echo "⚠️ 静态编译失败，自动切换到动态模式..."
        sudo gcc -Wall -Wextra -O2 -pthread unhide-linux*.c unhide-output.c -o unhide-linux
        sudo gcc -Wall -Wextra -O2 unhide-tcp*.c unhide-output.c -o unhide-tcp
    fi
else
    echo "使用动态编译模式..."
    sudo gcc -Wall -Wextra -O2 -pthread unhide-linux*.c unhide-output.c -o unhide-linux
    sudo gcc -Wall -Wextra -O2 unhide-tcp*.c unhide-output.c -o unhide-tcp
fi

echo "========== 安装可执行文件 =========="
sudo cp -f unhide-linux unhide-tcp "$UNHIDE_BIN_DIR"/
sudo chmod +x "$UNHIDE_BIN_DIR"/unhide-linux "$UNHIDE_BIN_DIR"/unhide-tcp

if [ ! -f "$UNHIDE_BIN_DIR/unhide" ]; then
    sudo ln -s "$UNHIDE_BIN_DIR/unhide-linux" "$UNHIDE_BIN_DIR/unhide"
fi

echo "========== 验证安装 =========="
if command -v unhide >/dev/null 2>&1; then
    echo "✅ Unhide 安装成功"
    unhide --version || echo "unhide 版本检测完成"
else
    echo "❌ 安装失败，请查看日志: $LOGFILE"
    exit 1
fi

echo "✅ 全部完成！日志文件: $LOGFILE"
#!/bin/bash
#
# 自动编译安装 unhide (兼容 AlmaLinux / CentOS 7/8/9)
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

PKG_TOOL=""
if command -v dnf >/dev/null 2>&1; then
    PKG_TOOL="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_TOOL="yum"
else
    echo "❌ 未找到 yum/dnf，请手动安装依赖"
    exit 1
fi

echo "========== 安装依赖 =========="
sudo $PKG_TOOL install -y git gcc make glibc-devel net-tools lsof || true

# 检查 glibc-static
if [ ! -f /usr/lib64/libc.a ]; then
    echo "⚠️ 检测到系统缺少 /usr/lib64/libc.a (glibc-static)，将跳过静态编译"
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
    sudo ./build_all.sh
    STATUS=$?
    set -e

    if [ $STATUS -ne 0 ]; then
        echo "⚠️ 静态编译失败，自动切换到动态编译模式..."
        sudo sed -i 's/-static//g' Makefile
        sudo ./build_all.sh
    fi
else
    echo "使用动态编译模式..."
    sudo sed -i 's/-static//g' Makefile
    sudo ./build_all.sh
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
    echo "❌ 安装失败，请检查日志: $LOGFILE"
    exit 1
fi

echo "✅ 全部完成！日志已保存至 $LOGFILE"
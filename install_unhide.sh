#!/bin/bash
#
# 自动编译安装 unhide (兼容 AlmaLinux/CentOS 7/8/9)
# 作者: Qiu
# 日期: 2025-10-29
#

set -e

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

echo "========== 安装依赖 =========="
if [[ "$ID" =~ (centos|rhel|almalinux|rocky) ]]; then
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git gcc make glibc-devel net-tools lsof
    else
        sudo yum install -y git gcc make glibc-devel net-tools lsof
    fi
else
    echo "⚠️ 未知系统类型：$ID，尝试使用通用依赖安装"
    sudo yum install -y git gcc make glibc-devel net-tools lsof || true
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
sudo ./build_all.sh

echo "========== 安装可执行文件 =========="
sudo cp -f unhide-linux unhide-tcp "$UNHIDE_BIN_DIR"/
sudo chmod +x "$UNHIDE_BIN_DIR"/unhide-linux "$UNHIDE_BIN_DIR"/unhide-tcp

# 方便直接执行
if [ ! -f "$UNHIDE_BIN_DIR/unhide" ]; then
    sudo ln -s "$UNHIDE_BIN_DIR/unhide-linux" "$UNHIDE_BIN_DIR/unhide"
fi

echo "========== 验证安装 =========="
if command -v unhide >/dev/null 2>&1; then
    echo "✅ Unhide 安装成功，版本信息如下："
    unhide --version || echo "unhide 已安装"
else
    echo "❌ 安装失败，请检查日志"
    exit 1
fi
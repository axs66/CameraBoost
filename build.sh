#!/bin/bash

# CameraBoost 构建脚本
# 支持 Rootless 和传统越狱环境

echo "🚀 开始构建 CameraBoost..."

# 检查 THEOS 环境
if [ -z "$THEOS" ]; then
    echo "❌ 错误: 未找到 THEOS 环境"
    echo "请确保已正确安装和配置 THEOS"
    exit 1
fi

# 清理之前的构建
echo "🧹 清理之前的构建文件..."
make clean

# 构建项目
echo "🔨 开始编译..."
make package

if [ $? -eq 0 ]; then
    echo "✅ 构建成功!"
    echo "📦 安装包位置: packages/"
    echo ""
    echo "安装方法:"
    echo "1. 将 .deb 文件传输到设备"
    echo "2. 使用 Sileo 或 Filza 安装"
    echo "3. 重启相机应用"
    echo ""
    echo "配置方法:"
    echo "1. 打开设置应用"
    echo "2. 找到 CameraBoost"
    echo "3. 根据需要配置功能"
else
    echo "❌ 构建失败!"
    echo "请检查错误信息并修复问题"
    exit 1
fi

#!/bin/bash

# CameraBoost 构建测试脚本

echo "🔍 检查项目结构..."

# 检查必需文件
if [ ! -d "PSHeader" ]; then
    echo "❌ PSHeader 目录不存在"
    exit 1
fi

if [ ! -f "Tweak.x" ]; then
    echo "❌ Tweak.x 文件不存在"
    exit 1
fi

if [ ! -f "Makefile" ]; then
    echo "❌ Makefile 文件不存在"
    exit 1
fi

echo "✅ 项目结构检查通过"

# 检查 PSHeader 文件
echo "🔍 检查 PSHeader 文件..."

required_files=(
    "PSHeader/CameraMacros.h"
    "PSHeader/Misc.h"
    "PSHeader/PS.h"
    "PSHeader/CameraApp/CAMViewfinderViewController.h"
    "PSHeader/CameraApp/CAMElapsedTimeView.h"
    "PSHeader/CameraApp/CAMCaptureCapabilities.h"
    "PSHeader/CameraApp/CAMUserPreferences.h"
    "PSHeader/CameraApp/CAMControlStatusIndicator.h"
    "PSHeader/CameraApp/CAMFramerateIndicatorView.h"
    "PSHeader/CameraApp/CAMBottomBar.h"
    "PSHeader/CameraApp/CAMDynamicShutterControl.h"
    "PSHeader/CameraApp/CAMShutterButton.h"
    "PSHeader/CameraApp/CUCaptureController.h"
    "PSHeader/CameraApp/CAMCaptureEngine.h"
    "PSHeader/CameraApp/CAMCaptureMovieFileOutput.h"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "❌ 缺少以下 PSHeader 文件:"
    for file in "${missing_files[@]}"; do
        echo "   - $file"
    done
    exit 1
fi

echo "✅ PSHeader 文件检查通过"

# 检查 Makefile 配置
echo "🔍 检查 Makefile 配置..."

if grep -q "I./PSHeader" Makefile; then
    echo "✅ Makefile 配置正确"
else
    echo "❌ Makefile 中缺少 PSHeader 路径配置"
    echo "请确保 Makefile 中包含: CameraBoost_CFLAGS = -fobjc-arc -I./PSHeader"
    exit 1
fi

echo ""
echo "🎉 所有检查通过！项目已准备就绪"
echo ""
echo "现在可以构建项目:"
echo "make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless"

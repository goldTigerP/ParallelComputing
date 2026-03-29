#!/bin/bash

# Linux/macOS CUDA项目构建脚本
# 要求：已安装CUDA Toolkit、CMake、GCC

set -e  # 遇到错误立即退出

echo "========================================"
echo "   CUDA向量运算项目 - Unix构建脚本"
echo "========================================"

# 检查环境
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ 错误: 未找到 $1"
        echo "   $2"
        exit 1
    fi
}

echo "🔍 检查构建环境..."

check_command nvcc "请安装CUDA Toolkit: https://developer.nvidia.com/cuda-downloads"
check_command cmake "请安装CMake: sudo apt install cmake 或 brew install cmake"
check_command g++ "请安装GCC: sudo apt install build-essential 或 xcode-select --install"

echo "✅ CUDA编译器检查通过"
nvcc --version

echo "✅ CMake检查通过"
cmake --version

echo "✅ GCC编译器检查通过"  
g++ --version

# 检测GPU
if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "🖥️ GPU设备信息:"
    nvidia-smi -L
else
    echo "⚠️ 警告: 未找到nvidia-smi，无法检测GPU"
fi

# 创建并进入构建目录
echo ""
echo "📁 创建构建目录..."
mkdir -p build
cd build

# 配置项目
echo ""
echo "🔧 配置项目..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# 编译项目
echo ""
echo "🏗️ 编译项目..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "✅ 编译成功！"
echo "📁 可执行文件位于: build/vector_add"

# 询问是否运行测试
echo ""
read -p "🚀 是否立即运行测试? (y/n): " choice
if [[ $choice == "y" || $choice == "Y" ]]; then
    echo ""
    echo "================= 运行测试 ================="
    ./vector_add
    echo "============================================"
fi

echo ""
echo "📋 其他可用命令:"
echo "   构建Debug版本:  cmake .. -DCMAKE_BUILD_TYPE=Debug && make"
echo "   清理:          make clean"  
echo "   重新配置:      rm -rf CMakeCache.txt && cmake .."
echo "   安装:          sudo make install"
echo "   打包:          cpack"

cd ..
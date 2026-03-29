@echo off
REM Windows CUDA项目构建脚本
REM 要求：已安装CUDA Toolkit、Visual Studio、CMake

echo ========================================
echo    CUDA向量运算项目 - Windows构建脚本
echo ========================================

REM 检查环境
where nvcc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 错误: 未找到CUDA编译器 nvcc
    echo    请确保已安装CUDA Toolkit并设置环境变量
    echo    下载地址: https://developer.nvidia.com/cuda-downloads
    pause
    exit /b 1
)

where cmake >nul 2>nul  
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 错误: 未找到CMake
    echo    请安装CMake并添加到PATH环境变量
    echo    下载地址: https://cmake.org/download/
    pause
    exit /b 1
)

echo ✅ CUDA编译器检查通过
nvcc --version

echo ✅ CMake检查通过  
cmake --version

REM 创建构建目录
if not exist "build" mkdir build
cd build

echo.
echo 🔧 配置项目...
cmake .. -G "Visual Studio 17 2022" -A x64
if %ERRORLEVEL% NEQ 0 (
    echo ❌ CMake配置失败
    pause
    exit /b 1
)

echo.  
echo 🏗️ 编译项目...
cmake --build . --config Release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 编译失败
    pause
    exit /b 1
)

echo.
echo ✅ 编译成功！
echo 📁 可执行文件位于: build\Release\vector_add.exe

echo.
echo 🚀 是否立即运行测试? (y/n)
set /p choice=
if /i "%choice%"=="y" (
    echo.
    echo ================= 运行测试 =================
    Release\vector_add.exe
    echo ============================================
)

echo.
echo 📋 其他可用命令:
echo    构建Debug版本:   cmake --build . --config Debug  
echo    清理:           cmake --build . --target clean
echo    重新配置:       del CMakeCache.txt ^&^& cmake ..
echo    打包:           cpack

cd ..
pause
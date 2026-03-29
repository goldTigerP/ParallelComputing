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

REM 检查Visual Studio安装
echo 🔍 检查Visual Studio安装...
set "VS_FOUND=0"

REM 检查VS2022
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" (
    echo ✅ 找到Visual Studio 2022 Community
    set "VS_FOUND=1"
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe" (
    echo ✅ 找到Visual Studio 2022 Professional  
    set "VS_FOUND=1"
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe" (
    echo ✅ 找到Visual Studio 2022 Enterprise
    set "VS_FOUND=1"
)

REM 检查VS2019
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" (
    echo ✅ 找到Visual Studio 2019 Community
    set "VS_FOUND=1"
)
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe" (
    echo ✅ 找到Visual Studio 2019 Professional
    set "VS_FOUND=1"
)

if "%VS_FOUND%"=="0" (
    echo ⚠️ 警告: 未找到Visual Studio安装
    echo    可能的解决方案:
    echo    1. 安装Visual Studio 2022 Community ^(免费^)
    echo    2. 使用MinGW-w64编译器
    echo    3. 使用Ninja构建系统
    echo.
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

REM 尝试多种生成器
set "CMAKE_SUCCESS=0"

REM 首先尝试VS2022
if "%VS_FOUND%"=="1" (
    echo 尝试使用 Visual Studio 17 2022...
    cmake .. -G "Visual Studio 17 2022" -A x64 >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo ✅ 成功配置: Visual Studio 17 2022
        set "CMAKE_SUCCESS=1"
        set "BUILD_GENERATOR=Visual Studio 17 2022"
    ) else (
        echo ⚠️ Visual Studio 17 2022 配置失败，尝试其他选项...
        
        REM 尝试VS2019
        cmake .. -G "Visual Studio 16 2019" -A x64 >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo ✅ 成功配置: Visual Studio 16 2019
            set "CMAKE_SUCCESS=1"
            set "BUILD_GENERATOR=Visual Studio 16 2019"
        )
    )
)

REM 如果VS不可用，尝试MinGW
if "%CMAKE_SUCCESS%"=="0" (
    echo 尝试使用 MinGW Makefiles...
    where gcc >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        cmake .. -G "MinGW Makefiles" >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo ✅ 成功配置: MinGW Makefiles
            set "CMAKE_SUCCESS=1" 
            set "BUILD_GENERATOR=MinGW Makefiles"
        )
    ) else (
        echo ⚠️ 未找到MinGW/GCC编译器
    )
)

REM 尝试Ninja
if "%CMAKE_SUCCESS%"=="0" (
    echo 尝试使用 Ninja...
    where ninja >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        cmake .. -G "Ninja" >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo ✅ 成功配置: Ninja
            set "CMAKE_SUCCESS=1"
            set "BUILD_GENERATOR=Ninja"
        )
    ) else (
        echo ⚠️ 未找到Ninja构建系统
    )
)

REM 最后尝试默认生成器
if "%CMAKE_SUCCESS%"=="0" (
    echo 尝试使用默认生成器...
    cmake .. >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo ✅ 成功配置: 默认生成器
        set "CMAKE_SUCCESS=1"
        set "BUILD_GENERATOR=默认"
    )
)

if "%CMAKE_SUCCESS%"=="0" (
    echo ❌ CMake配置失败
    echo.
    echo 📋 可能的解决方案:
    echo    1. 安装 Visual Studio 2022 Community
    echo       下载: https://visualstudio.microsoft.com/
    echo    2. 安装 MinGW-w64
    echo       下载: https://www.mingw-w64.org/
    echo    3. 使用 MSYS2 环境
    echo       下载: https://www.msys2.org/
    echo.
    echo 🔍 详细错误信息:
    cmake .. -G "Visual Studio 17 2022" -A x64
    pause
    exit /b 1
)

echo.  
echo 🏗️ 编译项目...
echo 使用生成器: %BUILD_GENERATOR%

if "%BUILD_GENERATOR%"=="MinGW Makefiles" (
    mingw32-make
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ MinGW编译失败
        pause
        exit /b 1
    )
    echo ✅ 编译成功！
    echo 📁 可执行文件位于: *.exe
) else if "%BUILD_GENERATOR%"=="Ninja" (
    ninja
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Ninja编译失败
        pause
        exit /b 1
    )
    echo ✅ 编译成功！
    echo 📁 可执行文件位于: *.exe
) else (
    cmake --build . --config Release
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ 编译失败
        pause
        exit /b 1
    )
    echo ✅ 编译成功！
    echo 📁 可执行文件位于: Release\vector_add.exe
)

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
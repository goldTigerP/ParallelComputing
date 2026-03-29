@echo off
REM Windows C++编译器检测脚本

echo ========================================
echo    Windows C++编译器检测工具
echo ========================================

echo 🔍 正在检查系统中可用的C++编译器...
echo.

REM 1. 检查MSVC (Microsoft Visual C++)
echo 📋 Microsoft Visual C++ (MSVC):
echo ----------------------------------------
where cl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 MSVC 编译器
    for /f "tokens=*" %%i in ('where cl 2^>nul') do echo    路径: %%i
    echo    版本信息:
    cl 2>&1 | findstr "Microsoft" | head -1
) else (
    echo ❌ 未找到 MSVC 编译器
)

REM 检查Visual Studio安装
echo.
echo 📁 Visual Studio 安装检查:
if exist "C:\Program Files\Microsoft Visual Studio\" (
    echo ✅ 找到 Visual Studio 安装
    dir "C:\Program Files\Microsoft Visual Studio" /b 2>nul
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\" (
    echo ✅ 找到 Visual Studio 安装 (x86)
    dir "C:\Program Files (x86)\Microsoft Visual Studio" /b 2>nul
)

echo.

REM 2. 检查MinGW/GCC
echo 🐧 MinGW/GCC:
echo ----------------------------------------
where gcc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 GCC 编译器
    for /f "tokens=*" %%i in ('where gcc 2^>nul') do echo    路径: %%i
    echo    版本信息:
    gcc --version | head -1
) else (
    echo ❌ 未找到 GCC 编译器
)

where g++ >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 G++ 编译器
    for /f "tokens=*" %%i in ('where g++ 2^>nul') do echo    路径: %%i
) else (
    echo ❌ 未找到 G++ 编译器
)

REM 检查MinGW特定版本
where mingw32-gcc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 MinGW32 编译器
    mingw32-gcc --version | head -1
)

where x86_64-w64-mingw32-gcc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 MinGW-w64 编译器
    x86_64-w64-mingw32-gcc --version | head -1
)

echo.

REM 3. 检查Clang
echo 🔥 Clang/LLVM:
echo ----------------------------------------
where clang >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Clang 编译器
    for /f "tokens=*" %%i in ('where clang 2^>nul') do echo    路径: %%i
    echo    版本信息:
    clang --version | head -1
) else (
    echo ❌ 未找到 Clang 编译器
)

where clang++ >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Clang++ 编译器
    for /f "tokens=*" %%i in ('where clang++ 2^>nul') do echo    路径: %%i
) else (
    echo ❌ 未找到 Clang++ 编译器
)

echo.

REM 4. 检查Intel编译器
echo 🚀 Intel C++ Compiler:
echo ----------------------------------------
where icl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Intel C++ 编译器 (Windows)
    icl 2>&1 | head -1
) else (
    echo ❌ 未找到 Intel C++ 编译器 (Windows版本)
)

where icc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Intel C++ 编译器 (Linux兼容版本)
    icc --version | head -1
) else (
    echo ❌ 未找到 Intel C++ 编译器 (Linux兼容版本)
)

echo.

REM 5. 检查其他构建工具
echo 🔨 构建工具:
echo ----------------------------------------
where make >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Make
    make --version | head -1
) else (
    echo ❌ 未找到 Make
)

where mingw32-make >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 MinGW Make
    mingw32-make --version | head -1
) else (
    echo ❌ 未找到 MinGW Make
)

where ninja >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Ninja
    ninja --version
) else (
    echo ❌ 未找到 Ninja
)

where cmake >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 CMake
    cmake --version | head -1
) else (
    echo ❌ 未找到 CMake
)

echo.

REM 6. 检查CUDA
echo 🎯 CUDA工具链:
echo ----------------------------------------
where nvcc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 NVCC (CUDA编译器)
    for /f "tokens=*" %%i in ('where nvcc 2^>nul') do echo    路径: %%i
    echo    版本信息:
    nvcc --version | findstr "release"
) else (
    echo ❌ 未找到 NVCC (CUDA编译器)
)

if defined CUDA_PATH (
    echo ✅ CUDA环境变量: %CUDA_PATH%
) else (
    echo ❌ 未设置 CUDA_PATH 环境变量
)

echo.

REM 7. 汇总和建议
echo 🎯 检测结果汇总:
echo ========================================

set "COMPILER_COUNT=0"

where cl >nul 2>nul && set /a COMPILER_COUNT+=1
where gcc >nul 2>nul && set /a COMPILER_COUNT+=1
where clang >nul 2>nul && set /a COMPILER_COUNT+=1

echo 找到 %COMPILER_COUNT% 个C++编译器

if %COMPILER_COUNT% EQU 0 (
    echo.
    echo ⚠️ 建议安装编译器:
    echo    1. MinGW-w64: https://www.mingw-w64.org/
    echo    2. MSYS2: https://www.msys2.org/
    echo    3. Visual Studio Community: https://visualstudio.microsoft.com/
    echo    4. LLVM/Clang: https://llvm.org/
) else (
    echo.
    echo 💡 推荐的CUDA编译配置:
    where cl >nul 2>nul && echo    - 使用MSVC: nvcc -ccbin cl
    where gcc >nul 2>nul && echo    - 使用GCC: nvcc -ccbin gcc  
    where clang >nul 2>nul && echo    - 使用Clang: nvcc -ccbin clang++
)

echo.
echo 📝 环境变量PATH内容:
echo %PATH%

pause
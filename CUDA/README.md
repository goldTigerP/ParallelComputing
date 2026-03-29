# CUDA向量运算性能测试

这是一个跨平台的CUDA并行计算项目，实现了高性能的向量运算，并提供了详细的性能分析和对比。

## 项目特色

🚀 **高性能并行计算**
- GPU加速的向量运算
- 多种算法实现对比
- 详细的性能分析

🌐 **跨平台支持**  
- Windows (Visual Studio / MinGW)
- Linux (GCC)
- macOS (Clang)

📊 **完整的基准测试**
- CPU vs GPU性能对比
- 不同数据规模测试
- 结果正确性验证

## 系统要求

### 硬件要求
- **GPU**: 支持CUDA的NVIDIA显卡 (计算能力 ≥ 5.0)
- **内存**: 推荐8GB以上 (测试大向量时)
- **存储**: 100MB可用空间

### 软件要求

#### Windows
- **CUDA Toolkit** 11.0+ 
  - 下载: [NVIDIA CUDA Downloads](https://developer.nvidia.com/cuda-downloads)
- **Visual Studio** 2019/2022 (推荐) 或 MinGW
- **CMake** 3.18+

#### Linux
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nvidia-cuda-toolkit cmake build-essential

# CentOS/RHEL  
sudo yum install cuda cmake gcc-c++

# Arch Linux
sudo pacman -S cuda cmake gcc
```

#### macOS
```bash
# 安装CUDA Toolkit (从NVIDIA官网下载)
# 使用Homebrew安装构建工具
brew install cmake
```

## 快速开始

### 方法1: 使用自动构建脚本 (推荐)

#### Windows
```cmd
REM 双击运行或在命令行执行
build_windows.bat
```

#### Linux/macOS
```bash
chmod +x build_unix.sh
./build_unix.sh
```

### 方法2: 使用CMake (跨平台)

```bash
# 创建构建目录
mkdir build && cd build

# 配置项目
cmake .. -DCMAKE_BUILD_TYPE=Release

# 编译
cmake --build . --config Release

# 运行
./vector_add        # Linux/macOS
# 或
Release\vector_add.exe  # Windows
```

### 方法3: 使用Makefile (备用)

```bash
# 检查环境
make check-cuda

# 编译并运行
make run

# 或分步执行
make            # 编译
make run        # 运行
```

## 项目结构

```
CUDA/
├── vector_add.cu           # 主要CUDA源代码
├── CMakeLists.txt          # CMake构建配置
├── Makefile                # 跨平台Makefile
├── build_windows.bat       # Windows自动构建脚本
├── build_unix.sh           # Unix自动构建脚本
└── README.md              # 项目文档
```

## 功能特性

### 核心算法

1. **向量加法**
   ```cuda
   __global__ void vectorAdd(float* a, float* b, float* c, int size) {
       int idx = blockIdx.x * blockDim.x + threadIdx.x;
       if (idx < size) c[idx] = a[idx] + b[idx];
   }
   ```

2. **复合运算**
   ```cuda
   // c[i] = a[i] * b[i] + a[i] + b[i]
   __global__ void vectorElementwiseMulSum(...) { ... }
   ```

3. **向量点积**
   ```cuda
   // 使用共享内存和归约算法
   __global__ void vectorDotProduct(...) { ... }
   ```

### 性能测试

- **多种数据规模**: 1M, 10M, 50M 元素
- **精确计时**: CUDA Events 高精度计时
- **结果验证**: 自动验证GPU和CPU结果一致性
- **吞吐量计算**: 每秒处理元素数量 (M元素/s)

### 优化特性

- **内存对齐**: 优化内存访问模式
- **编译器优化**: `-O3 -use_fast_math` 等标志  
- **多架构支持**: 支持不同GPU架构 (5.0, 6.1, 7.5, 8.6)
- **错误处理**: 完善的CUDA错误检查

## 性能预期

### 典型性能表现

| 操作类型 | 数据规模 | CPU时间 | GPU时间 | 加速比 |
|----------|----------|---------|---------|--------|
| 向量加法 | 10M元素 | ~40ms | ~2ms | 20x |
| 复合运算 | 10M元素 | ~80ms | ~3ms | 27x |
| 向量点积 | 10M元素 | ~100ms | ~5ms | 20x |

*实际性能取决于具体的GPU型号和系统配置*

### 影响因素

- **GPU架构**: 新架构通常性能更好
- **显存带宽**: 影响大数据集性能
- **数据传输**: PCIe带宽限制
- **计算复杂度**: 复杂运算GPU优势更明显

## 故障排除

### 常见问题

1. **找不到CUDA编译器**
   ```bash
   # 检查CUDA安装
   nvcc --version
   
   # Linux: 添加到PATH
   export PATH=/usr/local/cuda/bin:$PATH
   
   # Windows: 检查环境变量CUDA_PATH
   ```

2. **CMake找不到CUDA**
   ```bash
   # 指定CUDA路径
   cmake .. -DCUDAToolkit_ROOT=/usr/local/cuda
   ```

3. **运行时找不到GPU**
   ```bash
   # 检查GPU状态
   nvidia-smi
   
   # 检查CUDA运行时
   nvidia-smi -L
   ```

4. **编译错误：架构不匹配**
   ```bash
   # 查看GPU计算能力
   nvidia-smi --query-gpu=compute_cap --format=csv
   
   # 在CMakeLists.txt中调整CMAKE_CUDA_ARCHITECTURES
   ```

### 性能问题

1. **GPU性能不如预期**
   - 检查GPU温度和功耗限制
   - 确保使用独立显卡而非集成显卡
   - 关闭其他GPU占用程序

2. **内存不足**
   - 减少测试数据规模
   - 检查GPU显存大小
   - 使用分批处理

## 开发指南

### 添加新的核函数

1. 在`vector_add.cu`中添加CUDA核函数
2. 在`CudaVectorOperations`类中添加对应方法
3. 在`main()`函数中添加测试调用

### 性能优化建议

- **内存合并访问**: 确保相邻线程访问相邻内存
- **占用率优化**: 调整线程块大小
- **共享内存**: 利用共享内存减少全局内存访问
- **异步执行**: 使用CUDA流重叠计算和传输

## 扩展功能

### 可以添加的功能

- **矩阵运算**: 矩阵乘法、转置等
- **图像处理**: 滤波、变换等  
- **机器学习**: 神经网络层运算
- **科学计算**: FFT、求解器等

### 优化方向

- **多GPU支持**: 利用多个GPU并行
- **内存池**: 减少内存分配开销
- **JIT编译**: 运行时优化
- **精度选择**: 半精度浮点数支持

## 许可证

MIT License - 详见LICENSE文件

## 贡献

欢迎提交Issue和Pull Request！

## 相关资源

- [CUDA编程指南](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)
- [CUDA最佳实践](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/)
- [GPU性能优化](https://developer.nvidia.com/blog/how-optimize-data-transfers-cuda-cc/)

---

*这个项目展示了CUDA并行编程的基础概念和性能优化技术，适合学习GPU加速计算的开发者。*
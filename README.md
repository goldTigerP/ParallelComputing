# 并行计算项目

本项目专注于并行计算技术的研究和实现，涵盖了CPU并行计算的多个重要方面。

## 项目结构

```
ParallelComputing/
├── README.md
├── CPU/
│   ├── Makefile                          # 构建脚本
│   ├── simd_benchmark.cpp                # 基础SIMD性能测试
│   ├── advanced_simd_benchmark.cpp       # 高级SIMD性能测试  
│   ├── image_processing_simd.cpp         # 图像处理SIMD应用
│   └── SIMD_Performance_Report.md        # 详细性能分析报告
└── CUDA/
    ├── vector_add.cu                     # 完整CUDA向量运算
    ├── simple_vector_add.cu              # 简单CUDA示例
    ├── CMakeLists.txt                    # CMake跨平台构建
    ├── Makefile                          # 备用Makefile构建
    ├── build_windows.bat                 # Windows自动构建脚本
    ├── build_unix.sh                     # Unix自动构建脚本
    ├── CudaVectorAdd.vcxproj             # Visual Studio项目文件
    └── README.md                         # CUDA项目详细文档
```

## CPU并行计算 - SIMD技术

### 项目概述

SIMD（Single Instruction, Multiple Data）项目深入研究了现代CPU的向量化并行计算技术。通过多个基准测试和实际应用示例，全面分析了SIMD技术在不同计算场景下的性能表现。

### 核心发现

1. **超密集计算**: 可获得40-100倍的性能提升
2. **计算密集型任务**: 通常获得1.9-2.0倍的加速
3. **内存密集型任务**: 受带宽限制，提升相对有限(1.1-2.3倍)

### 快速开始

```bash
cd CPU
make all          # 编译所有测试程序
make run          # 运行基础性能测试
make run-advanced # 运行高级性能测试
make run-image    # 运行图像处理测试
```

## GPU并行计算 - CUDA技术

### 项目概述

CUDA项目实现了GPU加速的向量运算，提供完整的跨平台解决方案。包含从简单的向量加法到复杂的并行算法，展示了GPU并行计算的强大能力。

### 核心特性

1. **大规模并行**: 支持百万级元素的向量运算
2. **跨平台支持**: Windows/Linux/macOS全平台兼容
3. **性能优化**: 多种优化策略和详细分析
4. **完整工具链**: 自动化构建和测试脚本

### 快速开始

#### Windows
```cmd
cd CUDA
build_windows.bat  # 自动构建和运行
```

#### Linux/macOS
```bash
cd CUDA
chmod +x build_unix.sh
./build_unix.sh     # 自动构建和运行
```

### 性能对比

| 技术 | 并行度 | 适用场景 | 典型加速比 |
|------|--------|----------|------------|
| SIMD | 8-16元素 | CPU计算密集型 | 2-8x |
| CUDA | 数千线程 | 大规模并行 | 10-100x |

### 实测性能亮点

- **复杂数学运算**: 在50K-1M元素规模下稳定获得~2倍加速
- **密集计算循环**: 多次迭代可获得极高加速比(40-104倍)
- **图像处理应用**: VGA分辨率下RGB转灰度获得2.14倍加速

### 技术特色

1. **自定义对齐分配器**: 32字节内存对齐优化
2. **完整的性能测试框架**: 高精度计时和结果验证
3. **实际应用示例**: 图像处理中的SIMD应用
4. **详细的性能分析**: 量化不同因素对性能的影响

## 未来计划

1. **GPU并行计算**: CUDA/OpenCL实现
2. **多核心编程**: OpenMP, Thread池
3. **分布式计算**: MPI实现
4. **异构计算**: CPU+GPU协同

## 学习价值

- 深入理解现代CPU架构和并行计算原理
- 掌握底层性能优化技术
- 学习科学的性能测试和分析方法
- 获得实际项目中的并行优化经验

---

*这是一个从理论到实践的完整并行计算学习项目，适合对高性能计算感兴趣的开发者深入研究。*
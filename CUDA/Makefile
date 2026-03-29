# 跨平台CUDA Makefile
# 支持Windows (MinGW/MSYS2) 和 Unix系统

# 检测操作系统
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    # Windows路径分隔符
    PATHSEP := \\
    EXE_EXT := .exe
    # Windows下的CUDA路径 (可能需要调整)
    CUDA_PATH ?= $(CUDA_PATH)
    ifeq ($(CUDA_PATH),)
        CUDA_PATH := C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.0
    endif
else
    DETECTED_OS := $(shell uname -s)
    PATHSEP := /
    EXE_EXT :=
    # Unix下的CUDA路径
    CUDA_PATH ?= /usr/local/cuda
endif

# 编译器和工具
NVCC := nvcc
CXX := g++

# 项目配置
TARGET := vector_add$(EXE_EXT)
SOURCE := vector_add.cu

# 编译标志
NVCC_FLAGS := -std=c++17 --expt-relaxed-constexpr
CXX_FLAGS := -std=c++17

# 架构设置
ARCH_FLAGS := -gencode arch=compute_50,code=sm_50 \
              -gencode arch=compute_61,code=sm_61 \
              -gencode arch=compute_75,code=sm_75 \
              -gencode arch=compute_86,code=sm_86

# 优化标志
ifeq ($(DEBUG), 1)
    NVCC_FLAGS += -g -G -O0
    CXX_FLAGS += -g -O0
else
    NVCC_FLAGS += -O3 -use_fast_math
    CXX_FLAGS += -O3
endif

# 系统特定设置
ifeq ($(DETECTED_OS),Windows)
    # Windows设置
    NVCC_FLAGS += -Xcompiler /W3
    CXX_FLAGS += /W3 /EHsc
    LIBS := -lcudart -lcuda
    # 包含和库路径
    INCLUDES := -I"$(CUDA_PATH)/include"
    LIBDIRS := -L"$(CUDA_PATH)/lib/x64"
else ifeq ($(DETECTED_OS),Darwin)
    # macOS设置
    NVCC_FLAGS += -Xcompiler -Wall
    CXX_FLAGS += -Wall -Wextra
    LIBS := -lcudart -lcuda
    INCLUDES := -I$(CUDA_PATH)/include
    LIBDIRS := -L$(CUDA_PATH)/lib64
else
    # Linux设置
    NVCC_FLAGS += -Xcompiler -Wall
    CXX_FLAGS += -Wall -Wextra
    LIBS := -lcudart -lcuda
    INCLUDES := -I$(CUDA_PATH)/include
    LIBDIRS := -L$(CUDA_PATH)/lib64
endif

# 默认目标
all: info $(TARGET)

# 显示构建信息
info:
	@echo "========================================"
	@echo "  CUDA向量运算项目构建"
	@echo "========================================"
	@echo "检测到的操作系统: $(DETECTED_OS)"
	@echo "CUDA路径: $(CUDA_PATH)"
	@echo "编译目标: $(TARGET)"
	@echo "源文件: $(SOURCE)"
	@echo "========================================"

# 编译目标
$(TARGET): $(SOURCE)
	@echo "🔧 编译 $(SOURCE)..."
	$(NVCC) $(NVCC_FLAGS) $(ARCH_FLAGS) $(INCLUDES) $(LIBDIRS) -o $@ $< $(LIBS)
	@echo "✅ 编译完成: $(TARGET)"

# 运行测试
run: $(TARGET)
	@echo "🚀 运行CUDA向量运算测试..."
	.$(PATHSEP)$(TARGET)

# 调试版本
debug:
	$(MAKE) DEBUG=1

# 检查CUDA环境
check-cuda:
	@echo "🔍 检查CUDA环境..."
	@which $(NVCC) > /dev/null 2>&1 && echo "✅ 找到CUDA编译器: $$(which $(NVCC))" || echo "❌ 未找到CUDA编译器"
	@$(NVCC) --version 2>/dev/null && echo "✅ CUDA版本信息:" || echo "❌ 无法获取CUDA版本"
ifeq ($(DETECTED_OS),Linux)
	@which nvidia-smi > /dev/null 2>&1 && (echo "🖥️ GPU设备:"; nvidia-smi -L) || echo "⚠️ 未找到GPU或nvidia-smi"
endif

# 性能分析
profile: $(TARGET)
	@echo "📊 运行性能分析..."
ifeq ($(DETECTED_OS),Linux)
	nvprof ./$(TARGET)
else
	@echo "⚠️ 性能分析在此平台上可能不可用"
	./$(TARGET)
endif

# 清理
clean:
	@echo "🧹 清理编译文件..."
ifeq ($(DETECTED_OS),Windows)
	-del $(TARGET) 2>nul
else
	-rm -f $(TARGET)
endif
	@echo "✅ 清理完成"

# 安装
install: $(TARGET)
	@echo "📦 安装到系统..."
ifeq ($(DETECTED_OS),Windows)
	copy $(TARGET) C:\Windows\System32\ 2>nul || echo "⚠️ 需要管理员权限安装"
else
	sudo cp $(TARGET) /usr/local/bin/ || echo "⚠️ 需要sudo权限安装"
endif

# 帮助信息
help:
	@echo "CUDA向量运算项目 Makefile 使用指南"
	@echo "===================================="
	@echo "make              - 编译项目"
	@echo "make run          - 编译并运行"
	@echo "make debug        - 编译调试版本"
	@echo "make check-cuda   - 检查CUDA环境"
	@echo "make profile      - 运行性能分析"
	@echo "make clean        - 清理编译文件"
	@echo "make install      - 安装到系统"
	@echo "make help         - 显示此帮助"
	@echo ""
	@echo "环境变量:"
	@echo "CUDA_PATH         - CUDA安装路径"
	@echo "DEBUG=1           - 启用调试模式"

# 伪目标
.PHONY: all info run debug check-cuda profile clean install help
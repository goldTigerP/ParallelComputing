# Makefile for SIMD Benchmark

CXX = g++
CXXFLAGS = -std=c++17 -O3 -march=native -mavx -mavx2 -Wall -Wextra
TARGET = simd_benchmark
SOURCE = simd_benchmark.cpp
ADV_TARGET = advanced_simd_benchmark
ADV_SOURCE = advanced_simd_benchmark.cpp
IMG_TARGET = image_processing_simd
IMG_SOURCE = image_processing_simd.cpp

# 默认目标
all: $(TARGET) $(ADV_TARGET) $(IMG_TARGET)

# 编译主程序
$(TARGET): $(SOURCE)
	@echo "🔧 编译SIMD性能测试程序..."
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SOURCE)
	@echo "✅ 编译完成: $(TARGET)"

# 编译高级版本
$(ADV_TARGET): $(ADV_SOURCE)
	@echo "🔧 编译高级SIMD性能测试程序..."
	$(CXX) $(CXXFLAGS) -o $(ADV_TARGET) $(ADV_SOURCE)
	@echo "✅ 编译完成: $(ADV_TARGET)"

# 编译图像处理版本
$(IMG_TARGET): $(IMG_SOURCE)
	@echo "🔧 编译图像处理SIMD测试程序..."
	$(CXX) $(CXXFLAGS) -o $(IMG_TARGET) $(IMG_SOURCE)
	@echo "✅ 编译完成: $(IMG_TARGET)"

# 运行程序
run: $(TARGET)
	@echo "🚀 运行SIMD性能测试..."
	./$(TARGET)

# 运行高级版本
run-advanced: $(ADV_TARGET)
	@echo "🚀 运行高级SIMD性能测试..."
	./$(ADV_TARGET)

# 运行图像处理版本
run-image: $(IMG_TARGET)
	@echo "🚀 运行图像处理SIMD测试..."
	./$(IMG_TARGET)

# 调试版本
debug: CXXFLAGS = -std=c++17 -O0 -g -march=native -mavx -mavx2 -Wall -Wextra -DDEBUG
debug: $(TARGET)
	@echo "🐛 调试版本编译完成"

# 检查编译器支持的指令集
check-simd:
	@echo "🔍 检查编译器和CPU支持的SIMD指令集:"
	@echo "编译器版本:"
	@$(CXX) --version | head -1
	@echo "\nCPU信息:"
	@grep -E "(model name|flags)" /proc/cpuinfo | head -2
	@echo "\n支持的指令集标志:"
	@echo $(CXXFLAGS)

# 性能分析版本
profile: CXXFLAGS += -pg
profile: $(TARGET)
	@echo "📊 性能分析版本编译完成"

# 清理
clean:
	@echo "🧹 清理编译文件..."
	rm -f $(TARGET) $(ADV_TARGET) $(IMG_TARGET)
	rm -f gmon.out
	@echo "✅ 清理完成"

# 安装依赖（如果需要）
install-deps:
	@echo "📦 检查依赖..."
	@which $(CXX) > /dev/null || (echo "❌ 需要安装g++"; exit 1)
	@echo "✅ 所有依赖已满足"

# 帮助信息
help:
	@echo "🚀 SIMD性能测试 Makefile 使用指南"
	@echo "=================================="
	@echo "make               - 编译所有程序"
	@echo "make run           - 编译并运行基础测试"
	@echo "make run-advanced  - 编译并运行高级测试"
	@echo "make run-image     - 编译并运行图像处理测试"
	@echo "make debug         - 编译调试版本"
	@echo "make profile       - 编译性能分析版本"
	@echo "make check-simd    - 检查SIMD支持"
	@echo "make clean         - 清理编译文件"
	@echo "make help          - 显示此帮助"

.PHONY: all run run-advanced run-image debug profile clean install-deps check-simd help
#include <chrono>
#include <cstring>     // memcpy
#include <functional>  // 添加这个头文件
#include <immintrin.h> // AVX/SSE指令集
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

class SIMDCalculator {
private:
  std::vector<float> dataA;
  std::vector<float> dataB;
  std::vector<float> result;
  size_t size;

  // 随机数生成器
  std::mt19937 generator;
  std::uniform_real_distribution<float> distribution;

public:
  SIMDCalculator(size_t n)
      : size(n), generator(42), distribution(-100.0f, 100.0f) {
    // 确保数据大小是8的倍数（AVX一次处理8个float）
    size_t aligned_size = (n + 7) & ~7;
    dataA.resize(aligned_size);
    dataB.resize(aligned_size);
    result.resize(aligned_size);

    // 生成随机数据
    generateRandomData();
  }

  void generateRandomData() {
    std::cout << "🎲 生成随机数据 (大小: " << size << ")" << std::endl;

    for (size_t i = 0; i < size; ++i) {
      dataA[i] = distribution(generator);
      dataB[i] = distribution(generator);
    }

    // 显示前几个数据作为示例
    std::cout << "   示例数据 A: ";
    for (int i = 0; i < std::min(5, (int)size); ++i) {
      std::cout << std::fixed << std::setprecision(2) << dataA[i] << " ";
    }
    std::cout << "..." << std::endl;

    std::cout << "   示例数据 B: ";
    for (int i = 0; i < std::min(5, (int)size); ++i) {
      std::cout << std::fixed << std::setprecision(2) << dataB[i] << " ";
    }
    std::cout << "..." << std::endl;
  }

  // 普通的标量计算 - 加法
  double scalarAdd() {
    auto start = std::chrono::high_resolution_clock::now();

    for (size_t i = 0; i < size; ++i) {
      result[i] = dataA[i] + dataB[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return duration.count() / 1000.0; // 返回毫秒
  }

  // SIMD向量化计算 - 加法 (AVX)
  double simdAdd() {
    auto start = std::chrono::high_resolution_clock::now();

    size_t simd_size = size & ~7; // 向下对齐到8的倍数

    // AVX一次处理8个float - 使用未对齐加载
    for (size_t i = 0; i < simd_size; i += 8) {
      __m256 va = _mm256_loadu_ps(&dataA[i]); // 使用loadu_ps（未对齐加载）
      __m256 vb = _mm256_loadu_ps(&dataB[i]);
      __m256 vr = _mm256_add_ps(va, vb); // 并行加法
      _mm256_storeu_ps(&result[i], vr);  // 使用storeu_ps（未对齐存储）
    }

    // 处理剩余的元素（如果有的话）
    for (size_t i = simd_size; i < size; ++i) {
      result[i] = dataA[i] + dataB[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return duration.count() / 1000.0;
  }

  // 普通的标量计算 - 乘法
  double scalarMultiply() {
    auto start = std::chrono::high_resolution_clock::now();

    for (size_t i = 0; i < size; ++i) {
      result[i] = dataA[i] * dataB[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return duration.count() / 1000.0;
  }

  // SIMD向量化计算 - 乘法 (AVX)
  double simdMultiply() {
    auto start = std::chrono::high_resolution_clock::now();

    size_t simd_size = size & ~7; // 向下对齐到8的倍数

    // AVX一次处理8个float
    for (size_t i = 0; i < simd_size; i += 8) {
      __m256 va = _mm256_loadu_ps(&dataA[i]);
      __m256 vb = _mm256_loadu_ps(&dataB[i]);
      __m256 vr = _mm256_mul_ps(va, vb); // 并行乘法
      _mm256_storeu_ps(&result[i], vr);
    }

    // 处理剩余的元素
    for (size_t i = simd_size; i < size; ++i) {
      result[i] = dataA[i] * dataB[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return duration.count() / 1000.0;
  }

  // 混合运算：(A + B) * A
  double scalarMixedOp() {
    auto start = std::chrono::high_resolution_clock::now();

    for (size_t i = 0; i < size; ++i) {
      result[i] = (dataA[i] + dataB[i]) * dataA[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return duration.count() / 1000.0;
  }

  // SIMD混合运算：(A + B) * A
  double simdMixedOp() {
    auto start = std::chrono::high_resolution_clock::now();

    size_t simd_size = size & ~7;

    for (size_t i = 0; i < simd_size; i += 8) {
      __m256 va = _mm256_loadu_ps(&dataA[i]);
      __m256 vb = _mm256_loadu_ps(&dataB[i]);
      __m256 sum = _mm256_add_ps(va, vb); // A + B
      __m256 vr = _mm256_mul_ps(sum, va); // (A + B) * A
      _mm256_storeu_ps(&result[i], vr);
    }

    // 处理剩余元素
    for (size_t i = simd_size; i < size; ++i) {
      result[i] = (dataA[i] + dataB[i]) * dataA[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return duration.count() / 1000.0;
  }

  // 验证结果一致性
  bool verifyResults(const std::vector<float> &expected,
                     const std::vector<float> &actual) {
    const float epsilon = 1e-5f;
    for (size_t i = 0; i < size; ++i) {
      if (std::abs(expected[i] - actual[i]) > epsilon) {
        std::cout << "❌ 结果不匹配 at index " << i << ": expected "
                  << expected[i] << ", got " << actual[i] << std::endl;
        return false;
      }
    }
    return true;
  }

  void printResults(int count) {
    std::cout << "   结果示例: ";
    for (int i = 0; i < std::min(count, (int)size); ++i) {
      std::cout << std::fixed << std::setprecision(2) << result[i] << " ";
    }
    std::cout << "..." << std::endl;
  }

  const std::vector<float> &getResult() const { return result; }
};

void printHeader(const std::string &title) {
  std::cout << "\n" << std::string(60, '=') << std::endl;
  std::cout << "🚀 " << title << std::endl;
  std::cout << std::string(60, '=') << std::endl;
}

void runBenchmark(const std::string &operation,
                  std::function<double()> scalarFunc,
                  std::function<double()> simdFunc) {

  std::cout << "\n📊 " << operation << " 性能测试" << std::endl;
  std::cout << std::string(40, '-') << std::endl;

  // 运行标量版本
  std::cout << "🔄 标量计算中..." << std::endl;
  double scalarTime = scalarFunc();

  // 运行SIMD版本
  std::cout << "⚡ SIMD计算中..." << std::endl;
  double simdTime = simdFunc();

  // 计算加速比
  double speedup = scalarTime / simdTime;

  std::cout << "\n📈 性能结果:" << std::endl;
  std::cout << "   标量计算时间: " << std::fixed << std::setprecision(3)
            << scalarTime << " ms" << std::endl;
  std::cout << "   SIMD计算时间:  " << std::fixed << std::setprecision(3)
            << simdTime << " ms" << std::endl;
  std::cout << "   🎯 加速比:     " << std::fixed << std::setprecision(2)
            << speedup << "x" << std::endl;

  if (speedup > 1.5) {
    std::cout << "   ✅ SIMD显著提升性能!" << std::endl;
  } else if (speedup > 1.1) {
    std::cout << "   📈 SIMD有一定提升" << std::endl;
  } else {
    std::cout << "   ⚠️  SIMD提升有限（可能数据量太小）"
              << std::endl;
  }
}

int main() {
  printHeader("SIMD 并行计算性能对比测试");

  std::cout << "🔍 检查CPU支持的指令集:" << std::endl;

  // 检查AVX支持
  if (__builtin_cpu_supports("avx")) {
    std::cout << "   ✅ AVX支持 (256位向量, 8个float)" << std::endl;
  } else {
    std::cout << "   ❌ 不支持AVX" << std::endl;
  }

  if (__builtin_cpu_supports("avx2")) {
    std::cout << "   ✅ AVX2支持" << std::endl;
  }

  // 测试不同大小的数据集
  std::vector<size_t> test_sizes = {1000000};

  for (size_t test_size : test_sizes) {
    printHeader("测试数据大小: " + std::to_string(test_size) + " 个元素");

    SIMDCalculator calc(test_size);

    // 测试加法
    std::vector<float> scalarResult, simdResult;

    runBenchmark(
        "向量加法",
        [&]() {
          double time = calc.scalarAdd();
          scalarResult = calc.getResult();
          calc.printResults(5);
          return time;
        },
        [&]() {
          double time = calc.simdAdd();
          simdResult = calc.getResult();
          calc.printResults(5);
          return time;
        });

    // 验证结果一致性
    if (calc.verifyResults(scalarResult, simdResult)) {
      std::cout << "   ✅ 加法结果验证通过" << std::endl;
    }

    // 测试乘法
    runBenchmark(
        "向量乘法",
        [&]() {
          double time = calc.scalarMultiply();
          scalarResult = calc.getResult();
          calc.printResults(5);
          return time;
        },
        [&]() {
          double time = calc.simdMultiply();
          simdResult = calc.getResult();
          calc.printResults(5);
          return time;
        });

    if (calc.verifyResults(scalarResult, simdResult)) {
      std::cout << "   ✅ 乘法结果验证通过" << std::endl;
    }

    // 测试混合运算
    runBenchmark(
        "混合运算 (A+B)*A",
        [&]() {
          double time = calc.scalarMixedOp();
          scalarResult = calc.getResult();
          calc.printResults(5);
          return time;
        },
        [&]() {
          double time = calc.simdMixedOp();
          simdResult = calc.getResult();
          calc.printResults(5);
          return time;
        });

    if (calc.verifyResults(scalarResult, simdResult)) {
      std::cout << "   ✅ 混合运算结果验证通过" << std::endl;
    }

    std::cout << "\n" << std::string(60, '~') << std::endl;
  }

  printHeader("总结");
  std::cout << "🎯 关键发现:" << std::endl;
  std::cout << "   • AVX指令一次处理8个float，理论加速比8x" << std::endl;
  std::cout << "   • 实际加速比受内存带宽、Cache命中率等影响" << std::endl;
  std::cout << "   • 数据量越大，SIMD优势越明显" << std::endl;
  std::cout << "   • 复杂运算比简单运算更适合SIMD" << std::endl;
  std::cout << "\n💡 优化建议:" << std::endl;
  std::cout << "   • 确保数据对齐(32字节对齐用于AVX)" << std::endl;
  std::cout << "   • 批量处理大数据集" << std::endl;
  std::cout << "   • 考虑使用更高级的SIMD指令(AVX-512)" << std::endl;

  return 0;
}
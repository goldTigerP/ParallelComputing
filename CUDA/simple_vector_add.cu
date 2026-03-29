#include <cuda_runtime.h>
#include <iostream>
#include <vector>
#include <chrono>

// 简单的CUDA错误检查
#define CHECK_CUDA(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            std::cerr << "CUDA错误: " << cudaGetErrorString(err) << " 在 " << __FILE__ << ":" << __LINE__ << std::endl; \
            exit(1); \
        } \
    } while(0)

// CUDA核函数：简单向量加法
__global__ void simpleVectorAdd(float* a, float* b, float* c, int n) {
    // 获取线程ID
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    
    // 检查边界
    if (i < n) {
        c[i] = a[i] + b[i];
    }
}

int main() {
    std::cout << "🚀 简单CUDA向量加法示例\n" << std::endl;
    
    // 1. 设置向量大小
    const int N = 1000000;  // 100万个元素
    const size_t bytes = N * sizeof(float);
    
    std::cout << "📊 向量大小: " << N << " 个元素 (" << bytes/1024/1024 << " MB)" << std::endl;
    
    // 2. 分配主机(CPU)内存
    std::vector<float> h_a(N), h_b(N), h_c(N);
    
    // 3. 初始化数据
    std::cout << "🔧 初始化测试数据..." << std::endl;
    for (int i = 0; i < N; i++) {
        h_a[i] = i;
        h_b[i] = i * 2;
    }
    
    // 4. 分配设备(GPU)内存
    std::cout << "💾 分配GPU内存..." << std::endl;
    float *d_a, *d_b, *d_c;
    CHECK_CUDA(cudaMalloc(&d_a, bytes));
    CHECK_CUDA(cudaMalloc(&d_b, bytes));
    CHECK_CUDA(cudaMalloc(&d_c, bytes));
    
    // 5. 将数据从CPU复制到GPU
    std::cout << "📤 数据传输到GPU..." << std::endl;
    CHECK_CUDA(cudaMemcpy(d_a, h_a.data(), bytes, cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_b, h_b.data(), bytes, cudaMemcpyHostToDevice));
    
    // 6. 配置核函数启动参数
    int threadsPerBlock = 256;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
    
    std::cout << "⚙️ 核函数配置:" << std::endl;
    std::cout << "   线程每块: " << threadsPerBlock << std::endl;
    std::cout << "   块数量: " << blocksPerGrid << std::endl;
    std::cout << "   总线程数: " << blocksPerGrid * threadsPerBlock << std::endl;
    
    // 7. 启动CUDA核函数
    std::cout << "🚀 启动GPU计算..." << std::endl;
    
    auto gpu_start = std::chrono::high_resolution_clock::now();
    simpleVectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, N);
    CHECK_CUDA(cudaDeviceSynchronize()); // 等待GPU完成
    auto gpu_end = std::chrono::high_resolution_clock::now();
    
    // 8. 将结果从GPU复制回CPU
    std::cout << "📥 数据传输回CPU..." << std::endl;
    CHECK_CUDA(cudaMemcpy(h_c.data(), d_c, bytes, cudaMemcpyDeviceToHost));
    
    // 9. CPU版本对比
    std::cout << "💻 CPU版本计算..." << std::endl;
    std::vector<float> h_c_cpu(N);
    
    auto cpu_start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < N; i++) {
        h_c_cpu[i] = h_a[i] + h_b[i];
    }
    auto cpu_end = std::chrono::high_resolution_clock::now();
    
    // 10. 验证结果
    std::cout << "✅ 验证结果..." << std::endl;
    bool correct = true;
    for (int i = 0; i < N; i++) {
        if (abs(h_c[i] - h_c_cpu[i]) > 1e-5) {
            std::cout << "❌ 错误在索引 " << i << ": GPU=" << h_c[i] << ", CPU=" << h_c_cpu[i] << std::endl;
            correct = false;
            break;
        }
    }
    
    if (correct) {
        std::cout << "✅ 验证通过！GPU和CPU结果一致" << std::endl;
    }
    
    // 11. 性能统计
    auto gpu_time = std::chrono::duration_cast<std::chrono::microseconds>(gpu_end - gpu_start).count() / 1000.0;
    auto cpu_time = std::chrono::duration_cast<std::chrono::microseconds>(cpu_end - cpu_start).count() / 1000.0;
    
    std::cout << "\n📊 性能统计:" << std::endl;
    std::cout << "   CPU时间: " << cpu_time << " ms" << std::endl;
    std::cout << "   GPU时间: " << gpu_time << " ms" << std::endl;
    std::cout << "   加速比: " << cpu_time / gpu_time << "x" << std::endl;
    
    // 显示前几个结果
    std::cout << "\n📋 结果示例 (前10个):" << std::endl;
    for (int i = 0; i < 10; i++) {
        std::cout << "   " << h_a[i] << " + " << h_b[i] << " = " << h_c[i] << std::endl;
    }
    
    // 12. 清理内存
    std::cout << "\n🧹 清理GPU内存..." << std::endl;
    cudaFree(d_a);
    cudaFree(d_b);  
    cudaFree(d_c);
    
    std::cout << "✅ 程序执行完成！" << std::endl;
    
    return 0;
}
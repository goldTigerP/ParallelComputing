#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cmath>

// CUDA错误检查宏 - 跨平台兼容
#define CUDA_CHECK(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__ \
                      << " - " << cudaGetErrorString(error) << std::endl; \
            exit(EXIT_FAILURE); \
        } \
    } while(0)

// CUDA核函数：向量加法
__global__ void vectorAdd(const float* a, const float* b, float* c, int size) {
    // 计算全局线程索引
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    // 边界检查
    if (idx < size) {
        c[idx] = a[idx] + b[idx];
    }
}

// CUDA核函数：向量点积 (更复杂的计算)
__global__ void vectorDotProduct(const float* a, const float* b, float* partial_c, int size) {
    __shared__ float temp[256]; // 共享内存
    
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int tid = threadIdx.x;
    
    // 初始化共享内存
    temp[tid] = (idx < size) ? a[idx] * b[idx] : 0.0f;
    __syncthreads();
    
    // 归约求和
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tid < stride) {
            temp[tid] += temp[tid + stride];
        }
        __syncthreads();
    }
    
    // 每个block的结果存储
    if (tid == 0) {
        partial_c[blockIdx.x] = temp[0];
    }
}

// CUDA核函数：向量元素级乘法然后求和
__global__ void vectorElementwiseMulSum(const float* a, const float* b, float* c, int size) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (idx < size) {
        c[idx] = a[idx] * b[idx] + a[idx] + b[idx];
    }
}

class CudaVectorOperations {
private:
    float* d_a;          // GPU内存指针
    float* d_b;
    float* d_c;
    float* d_partial;
    size_t size;
    size_t bytes;
    
    // GPU设备信息
    int deviceId;
    cudaDeviceProp deviceProp;
    
public:
    CudaVectorOperations(size_t vectorSize) : size(vectorSize) {
        bytes = size * sizeof(float);
        
        // 获取GPU设备信息
        CUDA_CHECK(cudaGetDevice(&deviceId));
        CUDA_CHECK(cudaGetDeviceProperties(&deviceProp, deviceId));
        
        // 分配GPU内存
        CUDA_CHECK(cudaMalloc(&d_a, bytes));
        CUDA_CHECK(cudaMalloc(&d_b, bytes));
        CUDA_CHECK(cudaMalloc(&d_c, bytes));
        
        // 为点积分配额外内存
        int numBlocks = (size + 255) / 256;
        CUDA_CHECK(cudaMalloc(&d_partial, numBlocks * sizeof(float)));
        
        std::cout << "🚀 GPU设备信息:" << std::endl;
        std::cout << "   设备名称: " << deviceProp.name << std::endl;
        std::cout << "   计算能力: " << deviceProp.major << "." << deviceProp.minor << std::endl;
        std::cout << "   全局内存: " << deviceProp.totalGlobalMem / (1024*1024) << " MB" << std::endl;
        std::cout << "   SM数量: " << deviceProp.multiProcessorCount << std::endl;
        std::cout << "   最大线程/块: " << deviceProp.maxThreadsPerBlock << std::endl;
    }
    
    ~CudaVectorOperations() {
        // 释放GPU内存
        cudaFree(d_a);
        cudaFree(d_b);
        cudaFree(d_c);
        cudaFree(d_partial);
    }
    
    // CPU版本向量加法（用于性能对比）
    double cpuVectorAdd(const std::vector<float>& a, const std::vector<float>& b, std::vector<float>& c) {
        auto start = std::chrono::high_resolution_clock::now();
        
        for (size_t i = 0; i < size; ++i) {
            c[i] = a[i] + b[i];
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    // GPU版本向量加法
    double gpuVectorAdd(const std::vector<float>& a, const std::vector<float>& b, std::vector<float>& c) {
        // 数据传输到GPU
        CUDA_CHECK(cudaMemcpy(d_a, a.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, b.data(), bytes, cudaMemcpyHostToDevice));
        
        // 启动计时（仅计算核函数执行时间）
        cudaEvent_t start, stop;
        CUDA_CHECK(cudaEventCreate(&start));
        CUDA_CHECK(cudaEventCreate(&stop));
        CUDA_CHECK(cudaEventRecord(start));
        
        // 配置核函数执行参数
        int threadsPerBlock = 256;
        int blocksPerGrid = (size + threadsPerBlock - 1) / threadsPerBlock;
        
        // 启动核函数
        vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, size);
        
        // 检查核函数执行是否成功
        CUDA_CHECK(cudaGetLastError());
        
        // 停止计时
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));
        
        float milliseconds = 0;
        CUDA_CHECK(cudaEventElapsedTime(&milliseconds, start, stop));
        
        // 将结果从GPU传回CPU
        CUDA_CHECK(cudaMemcpy(c.data(), d_c, bytes, cudaMemcpyDeviceToHost));
        
        // 清理事件
        CUDA_CHECK(cudaEventDestroy(start));
        CUDA_CHECK(cudaEventDestroy(stop));
        
        return milliseconds;
    }
    
    // GPU版本向量复合运算
    double gpuComplexOperation(const std::vector<float>& a, const std::vector<float>& b, std::vector<float>& c) {
        // 数据传输到GPU
        CUDA_CHECK(cudaMemcpy(d_a, a.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, b.data(), bytes, cudaMemcpyHostToDevice));
        
        cudaEvent_t start, stop;
        CUDA_CHECK(cudaEventCreate(&start));
        CUDA_CHECK(cudaEventCreate(&stop));
        CUDA_CHECK(cudaEventRecord(start));
        
        int threadsPerBlock = 256;
        int blocksPerGrid = (size + threadsPerBlock - 1) / threadsPerBlock;
        
        // 执行复合运算: c[i] = a[i] * b[i] + a[i] + b[i]
        vectorElementwiseMulSum<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, size);
        CUDA_CHECK(cudaGetLastError());
        
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));
        
        float milliseconds = 0;
        CUDA_CHECK(cudaEventElapsedTime(&milliseconds, start, stop));
        
        CUDA_CHECK(cudaMemcpy(c.data(), d_c, bytes, cudaMemcpyDeviceToHost));
        
        CUDA_CHECK(cudaEventDestroy(start));
        CUDA_CHECK(cudaEventDestroy(stop));
        
        return milliseconds;
    }
    
    // CPU版本复合运算（用于对比）
    double cpuComplexOperation(const std::vector<float>& a, const std::vector<float>& b, std::vector<float>& c) {
        auto start = std::chrono::high_resolution_clock::now();
        
        for (size_t i = 0; i < size; ++i) {
            c[i] = a[i] * b[i] + a[i] + b[i];
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    // 计算点积
    double gpuDotProduct(const std::vector<float>& a, const std::vector<float>& b, float& result) {
        CUDA_CHECK(cudaMemcpy(d_a, a.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, b.data(), bytes, cudaMemcpyHostToDevice));
        
        cudaEvent_t start, stop;
        CUDA_CHECK(cudaEventCreate(&start));
        CUDA_CHECK(cudaEventCreate(&stop));
        CUDA_CHECK(cudaEventRecord(start));
        
        int threadsPerBlock = 256;
        int blocksPerGrid = (size + threadsPerBlock - 1) / threadsPerBlock;
        
        // 第一阶段：计算部分点积
        vectorDotProduct<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_partial, size);
        CUDA_CHECK(cudaGetLastError());
        
        // 第二阶段：在CPU上完成最终求和
        std::vector<float> partial_results(blocksPerGrid);
        CUDA_CHECK(cudaMemcpy(partial_results.data(), d_partial, blocksPerGrid * sizeof(float), cudaMemcpyDeviceToHost));
        
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));
        
        float milliseconds = 0;
        CUDA_CHECK(cudaEventElapsedTime(&milliseconds, start, stop));
        
        // 最终求和
        result = 0.0f;
        for (float val : partial_results) {
            result += val;
        }
        
        CUDA_CHECK(cudaEventDestroy(start));
        CUDA_CHECK(cudaEventDestroy(stop));
        
        return milliseconds;
    }
    
    size_t getSize() const { return size; }
    double getMegaElements() const { return size / 1000000.0; }
};

// 结果验证函数
bool verifyResults(const std::vector<float>& cpu_result, const std::vector<float>& gpu_result, float tolerance = 1e-5f) {
    for (size_t i = 0; i < cpu_result.size(); ++i) {
        if (std::abs(cpu_result[i] - gpu_result[i]) > tolerance) {
            std::cout << "❌ 验证失败在索引 " << i 
                      << ": CPU=" << cpu_result[i] 
                      << ", GPU=" << gpu_result[i] << std::endl;
            return false;
        }
    }
    return true;
}

void printPerformanceResults(const std::string& operation, 
                            double cpu_time, double gpu_time, 
                            double mega_elements, bool verified = true) {
    double speedup = cpu_time / gpu_time;
    double cpu_throughput = mega_elements / (cpu_time / 1000.0);
    double gpu_throughput = mega_elements / (gpu_time / 1000.0);
    
    std::cout << "\n🧮 " << operation << std::endl;
    std::cout << "   CPU时间: " << std::fixed << std::setprecision(3) << cpu_time << " ms (" 
              << std::fixed << std::setprecision(1) << cpu_throughput << " M元素/s)" << std::endl;
    std::cout << "   GPU时间: " << std::fixed << std::setprecision(3) << gpu_time << " ms (" 
              << std::fixed << std::setprecision(1) << gpu_throughput << " M元素/s)" << std::endl;
    std::cout << "   🚀 加速比: " << std::fixed << std::setprecision(2) << speedup << "x";
    
    if (verified) {
        std::cout << " ✅ 结果验证通过";
    } else {
        std::cout << " ❌ 结果验证失败";
    }
    
    if (speedup >= 10.0) {
        std::cout << " 🌟 卓越提升!" << std::endl;
    } else if (speedup >= 5.0) {
        std::cout << " ⚡ 显著提升!" << std::endl;
    } else if (speedup >= 2.0) {
        std::cout << " 📈 良好提升" << std::endl;
    } else if (speedup >= 1.1) {
        std::cout << " 📊 轻微提升" << std::endl;
    } else {
        std::cout << " ⚠️ 需要优化" << std::endl;
    }
}

int main() {
    std::cout << "🚀 CUDA向量运算性能测试\n";
    std::cout << std::string(60, '=') << std::endl;
    
    // 检查CUDA设备
    int deviceCount;
    CUDA_CHECK(cudaGetDeviceCount(&deviceCount));
    
    if (deviceCount == 0) {
        std::cerr << "❌ 未发现CUDA设备!" << std::endl;
        return -1;
    }
    
    std::cout << "📱 发现 " << deviceCount << " 个CUDA设备" << std::endl;
    
    // 测试不同大小的向量
    std::vector<size_t> test_sizes = {1000000, 10000000, 50000000};  // 1M, 10M, 50M元素
    
    for (size_t test_size : test_sizes) {
        std::cout << "\n" << std::string(60, '=') << std::endl;
        std::cout << "📊 测试向量规模: " << test_size << " 个元素 (" 
                  << std::fixed << std::setprecision(1) << (test_size / 1000000.0) << " M)" << std::endl;
        std::cout << "   内存需求: " << (test_size * sizeof(float) * 3 / 1024 / 1024) << " MB" << std::endl;
        std::cout << std::string(60, '-') << std::endl;
        
        CudaVectorOperations cuda_ops(test_size);
        
        // 生成测试数据
        std::vector<float> h_a(test_size);
        std::vector<float> h_b(test_size);
        std::vector<float> h_c_cpu(test_size);
        std::vector<float> h_c_gpu(test_size);
        
        // 初始化数据
        for (size_t i = 0; i < test_size; ++i) {
            h_a[i] = static_cast<float>(i % 1000) / 1000.0f;
            h_b[i] = static_cast<float>((i + 500) % 1000) / 1000.0f;
        }
        
        double mega_elements = cuda_ops.getMegaElements();
        
        // 测试1: 向量加法
        double cpu_add_time = cuda_ops.cpuVectorAdd(h_a, h_b, h_c_cpu);
        double gpu_add_time = cuda_ops.gpuVectorAdd(h_a, h_b, h_c_gpu);
        bool add_verified = verifyResults(h_c_cpu, h_c_gpu);
        printPerformanceResults("向量加法", cpu_add_time, gpu_add_time, mega_elements, add_verified);
        
        // 测试2: 复合运算
        double cpu_complex_time = cuda_ops.cpuComplexOperation(h_a, h_b, h_c_cpu);
        double gpu_complex_time = cuda_ops.gpuComplexOperation(h_a, h_b, h_c_gpu);
        bool complex_verified = verifyResults(h_c_cpu, h_c_gpu);
        printPerformanceResults("复合运算 (a*b+a+b)", cpu_complex_time, gpu_complex_time, mega_elements, complex_verified);
        
        // 测试3: 点积（仅对小向量测试，避免过长时间）
        if (test_size <= 10000000) {
            // CPU点积
            auto start = std::chrono::high_resolution_clock::now();
            float cpu_dot = 0.0f;
            for (size_t i = 0; i < test_size; ++i) {
                cpu_dot += h_a[i] * h_b[i];
            }
            auto end = std::chrono::high_resolution_clock::now();
            double cpu_dot_time = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
            
            // GPU点积
            float gpu_dot;
            double gpu_dot_time = cuda_ops.gpuDotProduct(h_a, h_b, gpu_dot);
            
            std::cout << "\n🔢 向量点积" << std::endl;
            std::cout << "   CPU结果: " << std::fixed << std::setprecision(6) << cpu_dot 
                      << " (时间: " << std::setprecision(3) << cpu_dot_time << " ms)" << std::endl;
            std::cout << "   GPU结果: " << std::fixed << std::setprecision(6) << gpu_dot 
                      << " (时间: " << std::setprecision(3) << gpu_dot_time << " ms)" << std::endl;
            
            bool dot_verified = std::abs(cpu_dot - gpu_dot) < 1e-3f;
            std::cout << "   🚀 加速比: " << std::fixed << std::setprecision(2) << (cpu_dot_time / gpu_dot_time) << "x";
            if (dot_verified) {
                std::cout << " ✅ 结果验证通过" << std::endl;
            } else {
                std::cout << " ❌ 结果差异: " << std::abs(cpu_dot - gpu_dot) << std::endl;
            }
        }
    }
    
    std::cout << "\n" << std::string(60, '=') << std::endl;
    std::cout << "🎯 CUDA性能分析总结:" << std::endl;
    std::cout << "   • 大规模并行: GPU在大数据集上优势明显" << std::endl;
    std::cout << "   • 内存带宽: GPU显存带宽远超CPU" << std::endl;
    std::cout << "   • 计算密度: 复杂运算更能发挥GPU优势" << std::endl;
    std::cout << "   • 数据传输: 数据传输开销需要考虑" << std::endl;
    
    std::cout << "\n💡 优化建议:" << std::endl;
    std::cout << "   • 批量处理: 一次处理大量数据减少传输开销" << std::endl;
    std::cout << "   • 流水线: 使用CUDA流实现计算和传输重叠" << std::endl;
    std::cout << "   • 内存合并: 确保全局内存访问合并" << std::endl;
    std::cout << "   • 占用率优化: 调整线程块大小提高占用率" << std::endl;
    
    return 0;
}
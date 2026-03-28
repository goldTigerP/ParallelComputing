#include <iostream>
#include <vector>
#include <random>
#include <chrono>
#include <iomanip>
#include <immintrin.h>

// 模拟RGB图像像素
struct RGB {
    float r, g, b;
};

class ImageProcessingSIMD {
private:
    std::vector<RGB> image;
    std::vector<float> grayscale;
    size_t width, height;
    
public:
    ImageProcessingSIMD(size_t w, size_t h) : width(w), height(h) {
        image.resize(width * height);
        grayscale.resize(width * height);
        
        // 生成随机图像数据
        std::mt19937 gen(42);
        std::uniform_real_distribution<float> dis(0.0f, 255.0f);
        
        for (auto& pixel : image) {
            pixel.r = dis(gen);
            pixel.g = dis(gen);
            pixel.b = dis(gen);
        }
    }
    
    // 标量版本：RGB转灰度
    double rgbToGrayscaleScalar() {
        auto start = std::chrono::high_resolution_clock::now();
        
        for (size_t i = 0; i < image.size(); ++i) {
            // 灰度公式: 0.299*R + 0.587*G + 0.114*B
            grayscale[i] = 0.299f * image[i].r + 
                          0.587f * image[i].g + 
                          0.114f * image[i].b;
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    // SIMD版本：RGB转灰度 (处理SoA格式)
    double rgbToGrayscaleSIMD() {
        // 重新组织数据为SoA格式
        std::vector<float> r_channel(image.size());
        std::vector<float> g_channel(image.size());
        std::vector<float> b_channel(image.size());
        
        for (size_t i = 0; i < image.size(); ++i) {
            r_channel[i] = image[i].r;
            g_channel[i] = image[i].g;
            b_channel[i] = image[i].b;
        }
        
        auto start = std::chrono::high_resolution_clock::now();
        
        __m256 coef_r = _mm256_set1_ps(0.299f);
        __m256 coef_g = _mm256_set1_ps(0.587f);
        __m256 coef_b = _mm256_set1_ps(0.114f);
        
        size_t simd_size = (image.size() / 8) * 8;
        
        for (size_t i = 0; i < simd_size; i += 8) {
            __m256 r = _mm256_loadu_ps(&r_channel[i]);
            __m256 g = _mm256_loadu_ps(&g_channel[i]);
            __m256 b = _mm256_loadu_ps(&b_channel[i]);
            
            __m256 gray = _mm256_add_ps(
                _mm256_mul_ps(r, coef_r),
                _mm256_add_ps(
                    _mm256_mul_ps(g, coef_g),
                    _mm256_mul_ps(b, coef_b)
                )
            );
            
            _mm256_storeu_ps(&grayscale[i], gray);
        }
        
        // 处理剩余像素
        for (size_t i = simd_size; i < image.size(); ++i) {
            grayscale[i] = 0.299f * r_channel[i] + 
                          0.587f * g_channel[i] + 
                          0.114f * b_channel[i];
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    // 标量版本：亮度调整
    double brightnessAdjustScalar(float factor) {
        auto start = std::chrono::high_resolution_clock::now();
        
        for (auto& pixel : image) {
            pixel.r = std::min(255.0f, pixel.r * factor);
            pixel.g = std::min(255.0f, pixel.g * factor);
            pixel.b = std::min(255.0f, pixel.b * factor);
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    // SIMD版本：亮度调整
    double brightnessAdjustSIMD(float factor) {
        auto start = std::chrono::high_resolution_clock::now();
        
        __m256 factor_vec = _mm256_set1_ps(factor);
        __m256 max_val = _mm256_set1_ps(255.0f);
        
        size_t simd_size = (image.size() * 3 / 8) * 8;
        float* pixel_data = reinterpret_cast<float*>(image.data());
        
        for (size_t i = 0; i < simd_size; i += 8) {
            __m256 values = _mm256_loadu_ps(&pixel_data[i]);
            __m256 adjusted = _mm256_mul_ps(values, factor_vec);
            __m256 clamped = _mm256_min_ps(adjusted, max_val);
            _mm256_storeu_ps(&pixel_data[i], clamped);
        }
        
        // 处理剩余数据
        for (size_t i = simd_size; i < image.size() * 3; ++i) {
            pixel_data[i] = std::min(255.0f, pixel_data[i] * factor);
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    // 高斯模糊 (简化版 3x3 kernel)
    double gaussianBlurScalar() {
        auto start = std::chrono::high_resolution_clock::now();
        
        std::vector<RGB> blurred = image;
        
        // 简化的3x3高斯核
        float kernel[3][3] = {
            {0.0625f, 0.125f, 0.0625f},
            {0.125f,  0.25f,  0.125f},
            {0.0625f, 0.125f, 0.0625f}
        };
        
        for (size_t y = 1; y < height - 1; ++y) {
            for (size_t x = 1; x < width - 1; ++x) {
                float r = 0, g = 0, b = 0;
                
                for (int dy = -1; dy <= 1; ++dy) {
                    for (int dx = -1; dx <= 1; ++dx) {
                        RGB& src = image[(y + dy) * width + (x + dx)];
                        float weight = kernel[dy + 1][dx + 1];
                        r += src.r * weight;
                        g += src.g * weight;
                        b += src.b * weight;
                    }
                }
                
                blurred[y * width + x] = {r, g, b};
            }
        }
        
        image = std::move(blurred);
        
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 1000.0;
    }
    
    size_t getPixelCount() const { return image.size(); }
    double getMegaPixels() const { return image.size() / 1000000.0; }
};

void printImageResults(const std::string& operation, 
                      double scalar_time, double simd_time,
                      double megapixels) {
    double speedup = scalar_time / simd_time;
    double scalar_mpps = megapixels / (scalar_time / 1000.0);
    double simd_mpps = megapixels / (simd_time / 1000.0);
    
    std::cout << "\n🖼️  " << operation << std::endl;
    std::cout << "   标量时间: " << std::fixed << std::setprecision(3) << scalar_time << " ms (" 
              << std::fixed << std::setprecision(1) << scalar_mpps << " MP/s)" << std::endl;
    std::cout << "   SIMD时间:  " << std::fixed << std::setprecision(3) << simd_time << " ms (" 
              << std::fixed << std::setprecision(1) << simd_mpps << " MP/s)" << std::endl;
    std::cout << "   🚀 加速比: " << std::fixed << std::setprecision(2) << speedup << "x";
    
    if (speedup >= 3.0) {
        std::cout << " ✨ 极佳提升!" << std::endl;
    } else if (speedup >= 2.0) {
        std::cout << " 🚀 显著提升!" << std::endl;
    } else if (speedup >= 1.3) {
        std::cout << " 📈 良好提升" << std::endl;
    } else {
        std::cout << " 📊 轻微提升" << std::endl;
    }
}

int main() {
    std::cout << "🎨 图像处理SIMD性能测试\n";
    std::cout << std::string(60, '=') << std::endl;
    
    // 测试不同分辨率
    std::vector<std::pair<size_t, size_t>> resolutions = {
        {640, 480},     // VGA
        {1920, 1080},   // Full HD
        {3840, 2160}    // 4K
    };
    
    for (auto [width, height] : resolutions) {
        std::cout << "\n📏 分辨率: " << width << " × " << height 
                  << " (" << std::fixed << std::setprecision(1) 
                  << (width * height / 1000000.0) << " MP)" << std::endl;
        std::cout << std::string(60, '-') << std::endl;
        
        ImageProcessingSIMD processor(width, height);
        double megapixels = processor.getMegaPixels();
        
        // RGB到灰度转换
        ImageProcessingSIMD temp1 = processor;  // 复制用于测试
        double scalar_gray = temp1.rgbToGrayscaleScalar();
        
        ImageProcessingSIMD temp2 = processor;
        double simd_gray = temp2.rgbToGrayscaleSIMD();
        
        printImageResults("RGB转灰度转换", scalar_gray, simd_gray, megapixels);
        
        // 亮度调整
        ImageProcessingSIMD temp3 = processor;
        double scalar_bright = temp3.brightnessAdjustScalar(1.2f);
        
        ImageProcessingSIMD temp4 = processor;
        double simd_bright = temp4.brightnessAdjustSIMD(1.2f);
        
        printImageResults("亮度调整 (+20%)", scalar_bright, simd_bright, megapixels);
        
        // 高斯模糊 (仅对小图像测试，计算量大)
        if (megapixels < 1.0) {
            ImageProcessingSIMD temp5 = processor;
            double blur_time = temp5.gaussianBlurScalar();
            std::cout << "\n🌫️  高斯模糊 (3×3核)" << std::endl;
            std::cout << "   标量时间: " << std::fixed << std::setprecision(3) << blur_time << " ms" << std::endl;
        }
    }
    
    std::cout << "\n" << std::string(60, '=') << std::endl;
    std::cout << "🎯 图像处理SIMD优势分析:" << std::endl;
    std::cout << "   • 像素级并行: SIMD天然适合像素操作" << std::endl;
    std::cout << "   • 数据布局: SoA格式比AoS格式更SIMD友好" << std::endl;
    std::cout << "   • 计算密度: 复杂滤波器显示更大优势" << std::endl;
    std::cout << "   • 内存访问: 连续访问模式最佳" << std::endl;
    
    std::cout << "\n💡 实际应用场景:" << std::endl;
    std::cout << "   • 实时视频处理: 30-60 FPS视频流" << std::endl;
    std::cout << "   • 批量图像处理: 照片编辑软件" << std::endl;
    std::cout << "   • 计算机视觉: 特征检测、边缘检测" << std::endl;
    std::cout << "   • 游戏图形: 后处理效果、滤镜" << std::endl;
    
    return 0;
}
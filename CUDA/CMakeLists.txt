cmake_minimum_required(VERSION 3.18)

# 项目配置
project(CudaVectorOperations 
    VERSION 1.0.0
    DESCRIPTION "跨平台CUDA向量运算性能测试"
    LANGUAGES CXX CUDA)

# C++标准设置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# CUDA设置
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

# 查找CUDA
find_package(CUDA REQUIRED)
enable_language(CUDA)

# 输出配置信息
message(STATUS "CUDA版本: ${CUDA_VERSION}")
message(STATUS "CUDA工具包路径: ${CUDA_TOOLKIT_ROOT_DIR}")

# 编译选项
if(WIN32)
    # Windows特定设置
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler /W3")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W3 /EHsc")
    # 设置CUDA架构
    set(CMAKE_CUDA_ARCHITECTURES "50;61;75;86")
else()
    # Linux/macOS设置
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler -Wall")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
    # 设置CUDA架构
    set(CMAKE_CUDA_ARCHITECTURES "50;61;75;86")
endif()

# Release模式优化
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    if(WIN32)
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3 -use_fast_math")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /O2")
    else()
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3 -use_fast_math")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
    endif()
endif()

# 可执行文件
add_executable(vector_add vector_add.cu)
add_executable(simple_vector_add simple_vector_add.cu)

# 设置CUDA属性
set_property(TARGET vector_add PROPERTY CUDA_SEPARABLE_COMPILATION ON)
set_property(TARGET simple_vector_add PROPERTY CUDA_SEPARABLE_COMPILATION ON)

# 链接CUDA库
if(WIN32)
    target_link_libraries(vector_add ${CUDA_LIBRARIES} ${CUDA_CUDART_LIBRARY})
    target_link_libraries(simple_vector_add ${CUDA_LIBRARIES} ${CUDA_CUDART_LIBRARY})
else()
    target_link_libraries(vector_add ${CUDA_LIBRARIES})
    target_link_libraries(simple_vector_add ${CUDA_LIBRARIES})
endif()

# 包含目录
target_include_directories(vector_add PRIVATE ${CUDA_INCLUDE_DIRS})
target_include_directories(simple_vector_add PRIVATE ${CUDA_INCLUDE_DIRS})

# 安装规则
install(TARGETS vector_add simple_vector_add
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)

# 打包配置
set(CPACK_PACKAGE_NAME "CudaVectorOperations")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${PROJECT_DESCRIPTION})
set(CPACK_PACKAGE_VENDOR "ParallelComputing Project")

if(WIN32)
    set(CPACK_GENERATOR "ZIP;NSIS")
else()
    set(CPACK_GENERATOR "TGZ;DEB")
endif()

include(CPack)

# 显示构建信息
message(STATUS "==================== 构建配置 ====================")
message(STATUS "项目名称: ${PROJECT_NAME}")
message(STATUS "项目版本: ${PROJECT_VERSION}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++标准: C++${CMAKE_CXX_STANDARD}")
message(STATUS "CUDA标准: CUDA C++${CMAKE_CUDA_STANDARD}")
message(STATUS "目标架构: ${CMAKE_CUDA_ARCHITECTURES}")
message(STATUS "安装路径: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "====================================================")
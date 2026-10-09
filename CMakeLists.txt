cmake_minimum_required(VERSION 3.18)
project(cuda_matrix_mul LANGUAGES CXX CUDA)

add_executable(matrix_mul matrix_mul.cu)

set_property(TARGET matrix_mul PROPERTY CUDA_ARCHITECTURES 120)
set_property(TARGET matrix_mul PROPERTY CUDA_STANDARD 17)

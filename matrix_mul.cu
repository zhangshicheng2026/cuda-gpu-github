#include <cuda_runtime.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <ctime>

#define TILE 16
#define CUDA_CHECK(call)                                                          \
    do {                                                                          \
        cudaError_t status = (call);                                              \
        if (status != cudaSuccess) {                                              \
            std::printf("CUDA error at %s:%d: %s\n", __FILE__, __LINE__,          \
                        cudaGetErrorString(status));                              \
            std::exit(1);                                                         \
        }                                                                         \
    } while (0)

__global__ void matMulKernel(const float* A, const float* B, float* C, int N) {
    __shared__ float tileA[TILE][TILE];
    __shared__ float tileB[TILE][TILE];

    int row = blockIdx.y * TILE + threadIdx.y;
    int col = blockIdx.x * TILE + threadIdx.x;
    float sum = 0.0f;

    for (int tile = 0; tile < (N + TILE - 1) / TILE; ++tile) {
        int aCol = tile * TILE + threadIdx.x;
        int bRow = tile * TILE + threadIdx.y;

        tileA[threadIdx.y][threadIdx.x] =
            (row < N && aCol < N) ? A[row * N + aCol] : 0.0f;
        tileB[threadIdx.y][threadIdx.x] =
            (bRow < N && col < N) ? B[bRow * N + col] : 0.0f;
        __syncthreads();

        for (int k = 0; k < TILE; ++k) {
            sum += tileA[threadIdx.y][k] * tileB[k][threadIdx.x];
        }
        __syncthreads();
    }

    if (row < N && col < N) {
        C[row * N + col] = sum;
    }
}

void fillMatrix(float* data, int N, float offset) {
    for (int i = 0; i < N * N; ++i) {
        data[i] = std::sin(static_cast<float>(i) * 0.001f + offset);
    }
}

void matMulCpu(const float* A, const float* B, float* C, int N) {
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            float sum = 0.0f;
            for (int k = 0; k < N; ++k) {
                sum += A[i * N + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
}

int main(int argc, char** argv) {
    int N = 1024;
    if (argc > 1) {
        N = std::atoi(argv[1]);
    }
    if (N <= 0) {
        N = 1024;
    }

    const size_t bytes = static_cast<size_t>(N) * N * sizeof(float);

    float* hA = new float[N * N];
    float* hB = new float[N * N];
    float* hC = new float[N * N];
    float* hRef = new float[N * N];

    fillMatrix(hA, N, 0.0f);
    fillMatrix(hB, N, 1.0f);

    float* dA = nullptr;
    float* dB = nullptr;
    float* dC = nullptr;
    CUDA_CHECK(cudaMalloc(&dA, bytes));
    CUDA_CHECK(cudaMalloc(&dB, bytes));
    CUDA_CHECK(cudaMalloc(&dC, bytes));
    CUDA_CHECK(cudaMemcpy(dA, hA, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, hB, bytes, cudaMemcpyHostToDevice));

    dim3 block(TILE, TILE);
    dim3 grid((N + TILE - 1) / TILE, (N + TILE - 1) / TILE);

    cudaEvent_t startEvent;
    cudaEvent_t stopEvent;
    CUDA_CHECK(cudaEventCreate(&startEvent));
    CUDA_CHECK(cudaEventCreate(&stopEvent));

    CUDA_CHECK(cudaEventRecord(startEvent));
    matMulKernel<<<grid, block>>>(dA, dB, dC, N);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stopEvent));
    CUDA_CHECK(cudaEventSynchronize(stopEvent));

    float gpuMs = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&gpuMs, startEvent, stopEvent));

    CUDA_CHECK(cudaMemcpy(hC, dC, bytes, cudaMemcpyDeviceToHost));

    std::clock_t cpuStart = std::clock();
    matMulCpu(hA, hB, hRef, N);
    float cpuMs = static_cast<float>(std::clock() - cpuStart) * 1000.0f / CLOCKS_PER_SEC;

    float maxError = 0.0f;
    for (int i = 0; i < N * N; ++i) {
        float error = std::fabs(hC[i] - hRef[i]);
        if (error > maxError) {
            maxError = error;
        }
    }

    std::printf("Matrix size : %d x %d\n", N, N);
    std::printf("GPU time    : %.3f ms\n", gpuMs);
    std::printf("CPU time    : %.3f ms\n", cpuMs);
    std::printf("Speedup     : %.2fx\n", cpuMs / gpuMs);
    std::printf("Max error   : %.6e\n", maxError);
    std::printf("Result      : %s\n", maxError < 1e-3f ? "PASS" : "FAIL");

    CUDA_CHECK(cudaEventDestroy(startEvent));
    CUDA_CHECK(cudaEventDestroy(stopEvent));
    CUDA_CHECK(cudaFree(dA));
    CUDA_CHECK(cudaFree(dB));
    CUDA_CHECK(cudaFree(dC));

    delete[] hA;
    delete[] hB;
    delete[] hC;
    delete[] hRef;

    return maxError < 1e-3f ? 0 : 1;
}

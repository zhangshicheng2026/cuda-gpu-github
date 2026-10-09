# CUDA GPU 矩阵乘法入门项目

这是一个最小可运行的 CUDA 入门项目：用 GPU 并行计算矩阵乘法 C = A × B，并与 CPU 单线程结果做对比校验。

## 这个程序做了什么

- 把矩阵 A、B 从内存拷贝到显存
- 启动 `N/16 × N/16` 个线程块，每个线程块包含 `16 × 16` 个线程
- 每个线程计算 C 的一个元素，并用共享内存分块加速
- 把结果拷回内存，和 CPU 版本比对，输出 `PASS` 或 `FAIL`

> 重要：项目必须放在纯英文路径（例如 D:\cuda-gpu-github），不要放在带中文的路径下，否则 nvcc 会静默失败。

## 环境要求

- Windows 10 / 11
- NVIDIA 独立显卡
- 较新的显卡驱动
- CUDA Toolkit 12.8 或更高版本
- Visual Studio 2022，安装时勾选“使用 C++ 的桌面开发”

在 PowerShell 里检查环境：

```powershell
nvidia-smi
nvcc --version
```

如果 `nvcc --version` 显示 12.6 或更早，需要先升级。RTX 50 系列显卡的架构代号是 `sm_120`，只有 CUDA 12.8 及以上版本支持。

## 安装 CUDA Toolkit 12.8+

1. 打开下载页面：https://developer.nvidia.com/cuda-12-8-0-download-archive
2. 依次选择 Windows、x86_64、你的 Windows 版本、exe(local)
3. 下载并安装，保持默认安装路径（英文路径，例如 `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8`）
4. 重新打开终端（或重启电脑），运行 `nvcc --version` 确认版本是 12.8+

## 编译和运行

双击 `build.bat`，或在项目目录执行：

```powershell
.\build.bat
.\build\matrix_mul.exe
```

也可以传入矩阵边长，例如：

```powershell
.\build\matrix_mul.exe 512
```

看到 `Result: PASS` 就说明 GPU 计算结果正确。

## 上传到 GitHub

1. 在 github.com 新建一个空仓库，不要勾选 README
2. 在本项目目录执行：

```powershell
git init
git reset
git add .
git commit -m "First CUDA matrix multiplication"
git branch -M main
git remote add origin https://github.com/你的用户名/仓库名.git
git push -u origin main
```

3. 登录时输入 GitHub 用户名和个人访问令牌，或改用 GitHub Desktop

## 常见问题

- 提示 `Could not set up the environment for Microsoft Visual Studio`：升级 CUDA 到 12.8+，或安装 VS2022 的 C++ 工具
- 提示不支持 `sm_120`：升级 CUDA 到 12.8+
- 运行时报错或 `FAIL`：先升级显卡驱动，再重新编译
- 用户名或 CUDA 安装路径包含中文时，编译可能报 `Access is denied` 或找不到 `cl.exe`：把 CUDA 装到默认英文路径，并在终端执行 `set TEMP=C:\Windows\Temp` 和 `set TMP=C:\Windows\Temp` 后再编译（`build.bat` 已自动尝试处理）

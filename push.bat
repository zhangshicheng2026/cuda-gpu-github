@echo off
setlocal
cd /d "%~dp0"

git config --global user.email "zzkk1122334455@qq.com"
git config --global user.name "zhangshicheng2026"

git add .
git commit -m "First CUDA matrix multiplication"

git remote remove origin >nul 2>nul
git remote add origin https://github.com/zhangshicheng2026/cuda-gpu-github.git
git branch -M main
git push -u origin main

if errorlevel 1 (
  echo.
  echo [FAIL] Please make sure you created an EMPTY GitHub repo named: cuda-gpu-github
  echo        Then sign in when GitHub asks for login.
  pause
  exit /b 1
)

echo.
echo [OK] Your code has been uploaded to GitHub.
pause

#!/bin/bash

# 简单的HTTP服务器启动脚本，用于本地测试

echo "启动本地Web服务器..."
echo "访问地址: http://localhost:8000"
echo "按 Ctrl+C 停止服务器"

# 尝试使用Python3
if command -v python3 &> /dev/null; then
    python3 -m http.server 8000
# 或者Python2
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer 8000
# 或者Node.js
elif command -v npx &> /dev/null; then
    npx http-server -p 8000
else
    echo "错误: 未找到Python或Node.js，无法启动HTTP服务器"
    echo "请手动启动Web服务器或直接用浏览器打开index.html"
    exit 1
fi

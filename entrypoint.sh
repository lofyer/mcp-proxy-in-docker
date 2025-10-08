#!/bin/bash
set -e

# 启动 VNC 服务器
echo "Starting VNC server on :0 (port 5900)..."
vncserver :0 -geometry 1920x1080 -depth 24 -localhost no

# 设置 DISPLAY 环境变量
export DISPLAY=:0

# 等待 VNC 启动
sleep 2

echo "VNC server started successfully"
echo "VNC Password: password"
echo "VNC Port: 5900"
echo ""

# 启动 supergateway 代理 browser-use
echo "Starting supergateway on port 8000..."
echo "Command: npx supergateway --port 8000 --stdio \"python /app/browser-use-app/mcp_server.py\""
echo ""
echo "Model Provider: ${MODEL_PROVIDER:-openai}"
echo "Model Name: ${MODEL_NAME:-gpt-4o-mini}"
echo ""

exec npx supergateway --port 8000 --stdio "python /app/browser-use-app/mcp_server.py"


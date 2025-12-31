#!/bin/bash
set -e

# Python 输出不缓冲，便于查看日志
export PYTHONUNBUFFERED=1

# 启动 VNC 服务器 (以 mesalogo 用户身份)
echo "Starting VNC server on :0 (port 5900)..."
vncserver :0 -geometry 1920x1080 -depth 24 -localhost no

# 设置 DISPLAY 环境变量
export DISPLAY=:0

# 等待 VNC 启动
sleep 2

echo "VNC server started successfully"
echo "VNC User: mesalogo"
echo "VNC Password: mesalogo"
echo "VNC Port: 5900"
echo ""

# ===== DesktopCommanderMCP 服务 (可选，独立运行) =====
# 终端控制、文件系统搜索、diff编辑
DESKTOP_COMMANDER_ENABLED=${DESKTOP_COMMANDER_ENABLED:-false}
DESKTOP_COMMANDER_PORT=${DESKTOP_COMMANDER_PORT:-8400}
DESKTOP_COMMANDER_TRANSPORT=${DESKTOP_COMMANDER_TRANSPORT:-streamableHttp}

if [ "$DESKTOP_COMMANDER_ENABLED" = "true" ]; then
  echo "Starting DesktopCommanderMCP on port ${DESKTOP_COMMANDER_PORT}..."
  DESKTOP_COMMANDER_DIR="/home/mesalogo/desktop-commander"
  # 使用 supergateway 将 STDIO 转换为 HTTP (SSE 或 Streamable HTTP)
  # Streamable HTTP 端点: http://localhost:${DESKTOP_COMMANDER_PORT}/mcp
  # SSE 端点: http://localhost:${DESKTOP_COMMANDER_PORT}/sse
  supergateway \
    --port ${DESKTOP_COMMANDER_PORT} \
    --outputTransport ${DESKTOP_COMMANDER_TRANSPORT} \
    --stdio "node ${DESKTOP_COMMANDER_DIR}/node_modules/@wonderwhy-er/desktop-commander/dist/index.js" &
  sleep 1
  echo "DesktopCommanderMCP started:"
  echo "  Port: ${DESKTOP_COMMANDER_PORT}"
  echo "  Transport: ${DESKTOP_COMMANDER_TRANSPORT}"
  if [ "$DESKTOP_COMMANDER_TRANSPORT" = "streamableHttp" ]; then
    echo "  Endpoint: http://0.0.0.0:${DESKTOP_COMMANDER_PORT}/mcp"
  else
    echo "  Endpoint: http://0.0.0.0:${DESKTOP_COMMANDER_PORT}/sse"
  fi
  echo ""
fi

# MCP 服务器类型 (必须明确指定)
# 可选值: browser-use, mcp-browser-use, playwright-mcp, nothing
MCP_SERVER_TYPE=${MCP_SERVER_TYPE:-}

if [ -z "$MCP_SERVER_TYPE" ]; then
  echo "ERROR: MCP_SERVER_TYPE environment variable is not set!"
  echo "Please set MCP_SERVER_TYPE to one of: browser-use, mcp-browser-use, playwright-mcp, nothing"
  exit 1
fi

echo "MCP Server Type: ${MCP_SERVER_TYPE}"
echo ""

case $MCP_SERVER_TYPE in
  "mcp-browser-use")
    # 使用 mcp-server-browser-use (更丰富的 MCP 工具集)
    # 项目地址: https://github.com/Saik0s/mcp-browser-use
    # 内置 HTTP/SSE 支持，默认端口 8383
    echo "Using mcp-server-browser-use (HTTP/SSE mode)"
    echo "LLM Provider: ${MCP_LLM_PROVIDER:-google}"
    echo "LLM Model: ${MCP_LLM_MODEL_NAME:-gemini-3-flash-preview}"
    echo "LLM Base URL: ${MCP_LLM_BASE_URL:-}"
    echo "Server Host: ${MCP_SERVER_HOST:-127.0.0.1}"
    echo "Server Port: ${MCP_SERVER_PORT:-8383}"
    echo ""
    
    # 测试 LLM 连接 (如果是 ollama)
    if [ "${MCP_LLM_PROVIDER}" = "ollama" ] && [ -n "${MCP_LLM_BASE_URL}" ]; then
      echo "Testing Ollama connection at ${MCP_LLM_BASE_URL}..."
      if curl -s --connect-timeout 5 "${MCP_LLM_BASE_URL}/api/tags" > /dev/null 2>&1; then
        echo "Ollama connection OK"
      else
        echo "WARNING: Cannot connect to Ollama at ${MCP_LLM_BASE_URL}"
        echo "The server may hang if LLM is not available"
      fi
      echo ""
    fi
    
    echo "Command: mcp-server-browser-use server -f"
    echo "Starting server..."
    exec mcp-server-browser-use server -f
    ;;
    
  "browser-use")
    # 使用 browser-use[cli] + supergateway
    echo "Using browser-use CLI server (basic browser automation)"
    echo "Model Provider: ${MODEL_PROVIDER:-openai}"
    echo "Model Name: ${MODEL_NAME:-gpt-4o-mini}"
    echo "HTTP Port: 8000 (via supergateway)"
    echo ""
    echo "Command: npx supergateway --port 8000 --stdio \"python /app/browser-use-app/mcp_server.py\""
    exec npx supergateway --port 8000 --stdio "python /app/browser-use-app/mcp_server.py"
    ;;
    
  "playwright-mcp")
    # 使用微软官方 Playwright MCP (纯工具模式，不需要 LLM)
    # 项目地址: https://github.com/microsoft/playwright-mcp
    # LLM 在客户端 (ABM-LLM) 调用工具，Playwright MCP 只提供浏览器操作工具
    PLAYWRIGHT_PORT=${PLAYWRIGHT_PORT:-8931}
    PLAYWRIGHT_HOST=${PLAYWRIGHT_HOST:-0.0.0.0}
    PLAYWRIGHT_HEADLESS=${PLAYWRIGHT_HEADLESS:-false}
    PLAYWRIGHT_BROWSER=${PLAYWRIGHT_BROWSER:-firefox}
    PLAYWRIGHT_MCP_DIR="/home/mesalogo/playwright-mcp"
    PLAYWRIGHT_USER_DATA_DIR="/home/mesalogo/browser-data"
    
    # 创建浏览器数据目录
    mkdir -p ${PLAYWRIGHT_USER_DATA_DIR}
    
    echo "Using Microsoft Playwright MCP (accessibility-based, no LLM needed)"
    echo "Host: ${PLAYWRIGHT_HOST}"
    echo "Port: ${PLAYWRIGHT_PORT}"
    echo "Headless: ${PLAYWRIGHT_HEADLESS}"
    echo "Browser: ${PLAYWRIGHT_BROWSER}"
    echo "User Data Dir: ${PLAYWRIGHT_USER_DATA_DIR}"
    echo "DISPLAY: ${DISPLAY}"
    echo ""
    echo "Available tools: browser_navigate, browser_click, browser_type, browser_snapshot, etc."
    echo "Full list: https://github.com/microsoft/playwright-mcp#tools"
    echo ""
    
    # 构建命令行参数
    # --ignore-https-errors: 忽略 SSL 证书错误，信任所有证书
    CMD_ARGS="--port ${PLAYWRIGHT_PORT} --host ${PLAYWRIGHT_HOST} --browser ${PLAYWRIGHT_BROWSER} --user-data-dir ${PLAYWRIGHT_USER_DATA_DIR} --ignore-https-errors"
    if [ "${PLAYWRIGHT_HEADLESS}" = "true" ]; then
      CMD_ARGS="${CMD_ARGS} --headless"
    fi
    
    echo "Command: node ${PLAYWRIGHT_MCP_DIR}/node_modules/@playwright/mcp/cli.js ${CMD_ARGS}"
    echo "Starting server..."
    exec node ${PLAYWRIGHT_MCP_DIR}/node_modules/@playwright/mcp/cli.js ${CMD_ARGS}
    ;;
    
  "nothing")
    # 不启动 MCP 服务器，仅保持容器运行 (用于调试)
    echo "MCP server disabled. Container will stay running for debugging."
    echo "You can exec into the container to test manually."
    echo ""
    # 保持容器运行
    exec tail -f /dev/null
    ;;
    
  *)
    echo "ERROR: Unknown MCP_SERVER_TYPE: ${MCP_SERVER_TYPE}"
    echo "Valid values: browser-use, mcp-browser-use, playwright-mcp, nothing"
    exit 1
    ;;
esac


# MCP Proxy in Docker

一个集成了 VNC 桌面环境和 MCP 服务器的 Docker 镜像，通过 supergateway 将任意 MCP stdio 服务器转换为 SSE (Server-Sent Events) HTTP API 并暴露出去。

## 目录

- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [访问方式](#访问方式)
- [配置 Browser-Use 模型](#配置-browser-use-模型)
- [自定义 MCP 服务器](#自定义-mcp-服务器)
- [项目结构](#项目结构)
- [技术栈](#技术栈)
- [常见问题](#常见问题)
- [许可证](#许可证)

## 功能特性

- ✅ **VNC 远程桌面** - 基于 TigerVNC + Xfce4，端口 5900，提供图形界面环境
- ✅ **MCP stdio → SSE 转换** - 通过 supergateway 将 stdio 协议转换为 HTTP SSE
- ✅ **HTTP API 暴露** - 在端口 8000 提供 MCP HTTP API 访问
- ✅ **示例 MCP 服务器** - 预装 browser-use[cli] 浏览器自动化服务器
- ✅ **可扩展架构** - 轻松替换为任意 MCP stdio 服务器
- ✅ **国内加速** - 使用阿里云镜像源 (apt, pip, npm)

## 快速开始

### 方式 1: 使用 docker-compose (推荐)

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止
docker-compose down
```

### 方式 2: 使用 docker 命令

```bash
# 构建镜像
docker build -t mcp-proxy-vnc .

# 运行容器
docker run -d \
  --name mcp-proxy-vnc \
  -p 5900:5900 \
  -p 8000:8000 \
  mcp-proxy-vnc

# 查看日志
docker logs -f mcp-proxy-vnc

# 停止容器
docker stop mcp-proxy-vnc
docker rm mcp-proxy-vnc
```

## 访问方式

### VNC 远程桌面

使用任意 VNC 客户端连接：

- **地址**: `localhost:5900` 或 `localhost::5900`
- **密码**: `password`

推荐的 VNC 客户端：
- **macOS**: [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
- **Windows**: [TightVNC](https://www.tightvnc.com/) 或 [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
- **Linux**: `vncviewer localhost:5900`

### MCP HTTP API

通过 HTTP 访问 MCP 服务器：

```bash
# 测试连接
curl http://localhost:8000

# 使用 MCP 客户端连接
# 地址: http://localhost:8000
```

## 项目结构

```
.
├── Dockerfile              # 容器镜像定义
├── entrypoint.sh           # 容器启动脚本
├── docker-compose.yml      # Docker Compose 配置
├── browser-use-app/        # Browser-Use 定制脚本
│   └── mcp_server.py       # MCP 服务器启动脚本（支持自定义模型）
├── PLAN.md                 # 项目计划文档
└── README.md               # 本文件
```

## 技术栈

- **基础镜像**: Debian Bookworm Slim
- **VNC 服务器**: TigerVNC
- **桌面环境**: Xfce4
- **Node.js**: LTS 版本
- **Python**: 3.11+ with uv
- **浏览器**: Chromium (通过 Playwright)
- **MCP stdio → SSE 转换**: supergateway
- **示例 MCP 服务器**: browser-use[cli] (可替换)

## 镜像源

为了加速构建，使用了以下阿里云镜像源：

- **APT**: `mirrors.aliyun.com`
- **PIP**: `mirrors.aliyun.com/pypi/simple/`
- **NPM**: `registry.npmmirror.com`

## 端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 5900 | VNC | 远程桌面访问 |
| 8000 | Supergateway | MCP HTTP API |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| DISPLAY | :0 | X11 显示编号 |

## 配置 Browser-Use 模型

默认使用 OpenAI 的 `gpt-4o-mini` 模型。你可以通过环境变量配置使用不同的模型。

### 方式 1: 修改 docker-compose.yml

编辑 `docker-compose.yml` 文件，取消注释并修改环境变量：

```yaml
environment:
  - DISPLAY=:0
  - MODEL_PROVIDER=openai          # 模型提供商
  - MODEL_NAME=gpt-4o              # 模型名称
  - OPENAI_API_KEY=sk-xxx          # API 密钥
```

### 方式 2: 使用 docker run 命令

```bash
docker run -d \
  -p 5900:5900 \
  -p 8000:8000 \
  -e MODEL_PROVIDER=anthropic \
  -e MODEL_NAME=claude-sonnet-4-0 \
  -e ANTHROPIC_API_KEY=sk-xxx \
  mcp-proxy-vnc
```

### 支持的模型提供商

| 提供商 | MODEL_PROVIDER | 环境变量 | 示例模型 |
|--------|----------------|----------|----------|
| OpenAI | `openai` | `OPENAI_API_KEY` | `gpt-4o`, `gpt-4o-mini` |
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` | `claude-sonnet-4-0`, `claude-opus-4-0` |
| Google Gemini | `google` | `GOOGLE_API_KEY` | `gemini-2.0-flash-exp`, `gemini-pro` |
| Azure OpenAI | `azure` | `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT` | `gpt-4o` |
| Ollama (本地) | `ollama` | - | `llama3.1:8b`, `qwen2.5:7b` |

### 使用自定义 OpenAI 兼容 API

```yaml
environment:
  - MODEL_PROVIDER=openai
  - MODEL_NAME=custom-model
  - BASE_URL=https://api.example.com/v1
  - API_KEY=your-api-key
```

### 配置示例

**使用 Anthropic Claude:**
```yaml
environment:
  - MODEL_PROVIDER=anthropic
  - MODEL_NAME=claude-sonnet-4-0
  - ANTHROPIC_API_KEY=sk-ant-xxx
```

**使用 Google Gemini:**
```yaml
environment:
  - MODEL_PROVIDER=google
  - MODEL_NAME=gemini-2.0-flash-exp
  - GOOGLE_API_KEY=AIzaSyxxx
```

**使用本地 Ollama:**
```yaml
environment:
  - MODEL_PROVIDER=ollama
  - MODEL_NAME=llama3.1:8b
  - BASE_URL=http://host.docker.internal:11434  # Ollama 地址
```

### 高级配置

如需更复杂的配置，可以直接修改 `browser-use-app/mcp_server.py` 文件。

## 自定义 MCP 服务器

这个镜像的核心功能是将**任意 MCP stdio 服务器**通过 supergateway 转换为 SSE HTTP API。默认使用 `browser-use` 作为示例，但你可以轻松替换为其他 MCP 服务器。

### 如何替换 MCP 服务器

#### 修改 Dockerfile

如果你的 MCP 服务器需要额外的依赖，修改 `Dockerfile`：

**步骤 1: 安装依赖**

```dockerfile
# 替换或添加你的 MCP 服务器依赖
# 例如：安装 filesystem MCP 服务器
RUN npm install -g @modelcontextprotocol/server-filesystem

# 或者：安装 Python MCP 服务器
RUN uv pip install --python $UV_PROJECT_ENVIRONMENT your-mcp-package
```

**步骤 2: 修改 entrypoint.sh**

```bash
# 使用你安装的 MCP 服务器
exec npx supergateway --port 8000 --stdio "your-mcp-server"
```

**步骤 3: 重新构建镜像**

```bash
docker build -t mcp-proxy-vnc .
```

### MCP stdio 服务器要求

任何符合以下条件的程序都可以作为 MCP 服务器：

1. ✅ 通过 **stdin/stdout** 进行通信（stdio 协议）
2. ✅ 实现 [MCP 协议规范](https://modelcontextprotocol.io/)
3. ✅ 可以通过命令行启动

### 常见 MCP 服务器示例

| MCP 服务器 | 安装命令 | 启动命令 |
|-----------|---------|---------|
| browser-use | `uv pip install browser-use[cli]` | `browser-use --mcp` |
| filesystem | `npm install -g @modelcontextprotocol/server-filesystem` | `npx @modelcontextprotocol/server-filesystem /path` |
| sqlite | `npm install -g @modelcontextprotocol/server-sqlite` | `npx @modelcontextprotocol/server-sqlite --db-path /path/db.sqlite` |
| github | `npm install -g @modelcontextprotocol/server-github` | `npx @modelcontextprotocol/server-github` |
| puppeteer | `npm install -g @modelcontextprotocol/server-puppeteer` | `npx @modelcontextprotocol/server-puppeteer` |

### 环境变量传递

如果你的 MCP 服务器需要环境变量（如 API keys），可以在 `docker-compose.yml` 中添加：

```yaml
services:
  mcp-proxy-vnc:
    environment:
      - DISPLAY=:0
      - GITHUB_TOKEN=your_token_here
      - OPENAI_API_KEY=your_key_here
```

或使用 docker run：

```bash
docker run -d \
  -p 5900:5900 \
  -p 8000:8000 \
  -e GITHUB_TOKEN=your_token \
  mcp-proxy-vnc
```

### 为什么需要 VNC？

某些 MCP 服务器（如 browser-use、puppeteer）需要运行浏览器，而浏览器需要图形界面环境。VNC 提供了：

- ✅ X11 显示服务器（DISPLAY=:0）
- ✅ 可视化调试能力
- ✅ 浏览器运行环境

如果你的 MCP 服务器**不需要**图形界面，可以：
1. 移除 VNC 相关配置以减小镜像体积
2. 或保留 VNC 用于调试和监控

## 故障排查

### VNC 无法连接

```bash
# 检查容器是否运行
docker ps | grep mcp-proxy-vnc

# 查看容器日志
docker logs mcp-proxy-vnc

# 检查端口是否开放
netstat -an | grep 5900
```

### Supergateway 无法访问

```bash
# 测试 HTTP 端口
curl http://localhost:8000

# 查看容器日志
docker logs -f mcp-proxy-vnc
```

### 浏览器无法启动或报"输入输出错误"

**原因：** 浏览器需要足够的共享内存和系统依赖。

**解决方案：**

1. **使用 docker-compose（推荐）**
   ```yaml
   services:
     mcp-proxy-vnc:
       shm_size: '2gb'  # 增加共享内存
   ```

2. **使用 docker run**
   ```bash
   docker run -d \
     --shm-size=2g \
     -p 5900:5900 -p 8000:8000 \
     mcp-proxy-vnc
   ```

3. **检查依赖**
   - VNC 服务器已启动
   - DISPLAY 环境变量已设置（:0）
   - Chromium 及其依赖已正确安装
   - 字体库已安装（fonts-liberation, fonts-noto-cjk）

4. **查看详细错误**
   ```bash
   # 进入容器
   docker exec -it mcp-proxy-vnc bash

   # 手动启动浏览器查看错误
   DISPLAY=:0 chromium --no-sandbox
   ```

## 开发说明

### 修改 VNC 密码

编辑 `Dockerfile`，修改以下行：

```dockerfile
RUN echo "your_password" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd
```

### 修改 VNC 分辨率

编辑 `entrypoint.sh`，修改以下行：

```bash
vncserver :0 -geometry 1920x1080 -depth 24 -localhost no
```

### 修改 Supergateway 端口

编辑 `entrypoint.sh` 和 `Dockerfile` 中的端口配置。

### 添加多个 MCP 服务器

如果需要同时运行多个 MCP 服务器，可以：

1. 在不同端口运行多个 supergateway 实例
2. 使用进程管理器（如 supervisord）
3. 创建多个容器，每个容器运行一个 MCP 服务器

## 许可证

MIT

## 贡献

欢迎提交 Issue 和 Pull Request！


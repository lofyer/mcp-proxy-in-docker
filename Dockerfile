FROM debian:bookworm-slim

# 配置 APT 阿里云镜像源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    curl \
    ca-certificates \
    gnupg \
    wget \
    iputils-ping \
    net-tools \
    dnsutils \
    sudo \
    chromium \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    # 浏览器运行所需的依赖
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    fontconfig \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    vim \
    # playwright 依赖
    libflite1 \
    libgtk-4-1 \
    libwoff1 \
    libgles2 \
    libevent-2.1-7 \
    libgstreamer-gl1.0-0 \
    libhyphen0 \
    libharfbuzz-icu0 \
    libwebpdemux2 \
    libenchant-2-2 \
    libmanette-0.2-0 \
    libgstreamer-plugins-bad1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js LTS (使用 NodeSource 官方源)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# 创建用户 mesalogo，设置密码，允许无密码 sudo
RUN useradd -m -s /bin/bash mesalogo && \
    echo "mesalogo:mesalogo" | chpasswd && \
    usermod -aG sudo mesalogo && \
    echo "mesalogo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置 VNC 密码 (mesalogo 用户)
RUN mkdir -p /home/mesalogo/.vnc && \
    echo "mesalogo" | vncpasswd -f > /home/mesalogo/.vnc/passwd && \
    chmod 600 /home/mesalogo/.vnc/passwd && \
    chown -R mesalogo:mesalogo /home/mesalogo/.vnc

# 创建 VNC 启动脚本 (mesalogo 用户)
RUN echo '#!/bin/sh' > /home/mesalogo/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /home/mesalogo/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /home/mesalogo/.vnc/xstartup && \
    echo 'exec startxfce4' >> /home/mesalogo/.vnc/xstartup && \
    chmod +x /home/mesalogo/.vnc/xstartup && \
    chown mesalogo:mesalogo /home/mesalogo/.vnc/xstartup

# 创建必要目录并设置权限
RUN mkdir -p /home/mesalogo/.config/mcp-server-browser-use && \
    mkdir -p /home/mesalogo/.local/state/mcp-server-browser-use && \
    mkdir -p /home/mesalogo/.config/browser-skills && \
    mkdir -p /home/mesalogo/.pip && \
    mkdir -p /home/mesalogo/.cache && \
    chown -R mesalogo:mesalogo /home/mesalogo

# 暴露端口
EXPOSE 5900 8000 8383 8931

# 设置工作目录
WORKDIR /home/mesalogo

# 切换到 mesalogo 用户
USER mesalogo

# 配置 PIP 阿里云镜像源
RUN echo "[global]" > /home/mesalogo/.pip/pip.conf && \
    echo "index-url = https://mirrors.aliyun.com/pypi/simple/" >> /home/mesalogo/.pip/pip.conf && \
    echo "trusted-host = mirrors.aliyun.com" >> /home/mesalogo/.pip/pip.conf

# 配置 NPM 阿里云镜像源
RUN npm config set registry https://registry.npmmirror.com

# 安装 uv (通过 pipx)
ENV PATH="/home/mesalogo/.local/bin:$PATH"
RUN pipx install uv

# 配置 uv 阿里云镜像源
ENV UV_INDEX_URL="https://mirrors.aliyun.com/pypi/simple/"

# 创建 uv 虚拟环境
ENV UV_PROJECT_ENVIRONMENT="/home/mesalogo/.venv"
RUN uv venv $UV_PROJECT_ENVIRONMENT

# ==================== 可选模块 ====================
# 注释或取消注释下面的块来启用/禁用对应模块

# ===== [模块1] browser-use[cli] (MCP_SERVER_TYPE=browser-use) =====
# 基础浏览器自动化，通过 supergateway 转换为 HTTP/SSE，端口 8000
# --- 开始 browser-use ---
# COPY browser-use-app /app/browser-use-app
# RUN chmod +x /app/browser-use-app/mcp_server.py && \
#     chown -R mesalogo:mesalogo /app
#RUN uv pip install --python $UV_PROJECT_ENVIRONMENT \
#     langchain-openai \
#     langchain-anthropic \
#     langchain-ollama \
#     browser-use[cli] \
#     playwright
# RUN sudo npm install -g supergateway
# --- 结束 browser-use ---

# ===== [模块2] mcp-server-browser-use (MCP_SERVER_TYPE=mcp-browser-use) =====
# 更丰富的 MCP 工具集，内置 HTTP/SSE 支持，端口 8383
# 项目地址: https://github.com/Saik0s/mcp-browser-use
# --- 开始 mcp-server-browser-use ---
RUN uv pip install --python $UV_PROJECT_ENVIRONMENT mcp-server-browser-use
# --- 结束 mcp-server-browser-use ---

# ===== [模块3] playwright-mcp (MCP_SERVER_TYPE=playwright-mcp) =====
# 微软官方 Playwright MCP，使用 accessibility snapshots，不需要 LLM
# 项目地址: https://github.com/microsoft/playwright-mcp
# --- 开始 playwright-mcp ---
# 用户级安装 @playwright/mcp (mesalogo 用户)
RUN mkdir -p /home/mesalogo/playwright-mcp && \
    cd /home/mesalogo/playwright-mcp && \
    npm init -y && \
    npm install @playwright/mcp@latest && \
    npx playwright install
# --- 结束 playwright-mcp ---

# ===== [模块4] DesktopCommanderMCP (终端+文件系统控制) =====
# 5.1k stars，终端控制、文件搜索、diff编辑、ripgrep集成
# 项目地址: https://github.com/wonderwhy-er/DesktopCommanderMCP
# 注意: 使用 STDIO 传输，需要通过 supergateway 转换为 HTTP/SSE
# --- 开始 desktop-commander ---
RUN mkdir -p /home/mesalogo/desktop-commander && \
    cd /home/mesalogo/desktop-commander && \
    npm init -y && \
    npm install @wonderwhy-er/desktop-commander
# 安装 supergateway 用于 STDIO 转 HTTP/SSE
RUN sudo npm install -g supergateway
# --- 结束 desktop-commander ---

# ==================== 可选模块结束 ====================

# 安装 playwright 浏览器 (两个模式共用)
RUN $UV_PROJECT_ENVIRONMENT/bin/playwright install chromium

# 将虚拟环境添加到 PATH
ENV PATH="$UV_PROJECT_ENVIRONMENT/bin:$PATH"

# 复制启动脚本 (放在最后，便于修改时快速重建)
COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

# 启动脚本
ENTRYPOINT ["/entrypoint.sh"]

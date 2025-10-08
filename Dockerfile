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
    # 浏览器运行所需的依赖
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
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
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js (使用官方脚本，然后配置阿里云源)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# 配置 NPM 阿里云镜像源
RUN npm config set registry https://registry.npmmirror.com

# 安装 Python3 和 pipx
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    && rm -rf /var/lib/apt/lists/*

# 配置 PIP 阿里云镜像源
RUN mkdir -p /root/.pip && \
    echo "[global]" > /root/.pip/pip.conf && \
    echo "index-url = https://mirrors.aliyun.com/pypi/simple/" >> /root/.pip/pip.conf && \
    echo "trusted-host = mirrors.aliyun.com" >> /root/.pip/pip.conf

# 确保 pipx 在 PATH 中
ENV PATH="/root/.local/bin:$PATH"

# 安装 uv (通过 pipx)
RUN pipx install uv

# 创建 uv 虚拟环境用于 browser-use
ENV UV_PROJECT_ENVIRONMENT="/opt/browser-use-env"
RUN uv venv $UV_PROJECT_ENVIRONMENT

# 配置 VNC 密码
RUN mkdir -p /root/.vnc && \
    echo "password" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# 创建 VNC 启动脚本
RUN echo '#!/bin/sh' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo 'exec startxfce4' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# 全局安装 supergateway
RUN npm install -g supergateway && \
    npx supergateway --help || true

# 预安装 browser-use 和 playwright 到虚拟环境
RUN uv pip install --python $UV_PROJECT_ENVIRONMENT langchain-openai langchain-anthropic langchain-ollama browser-use[cli] playwright && \
    $UV_PROJECT_ENVIRONMENT/bin/playwright install --with-deps --no-shell chromium

# 将虚拟环境添加到 PATH
ENV PATH="$UV_PROJECT_ENVIRONMENT/bin:$PATH"

# 暴露端口
EXPOSE 5900 8000

# 复制 browser-use 定制脚本
COPY browser-use-app /app/browser-use-app
RUN chmod +x /app/browser-use-app/mcp_server.py

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置工作目录
WORKDIR /root

# 启动脚本
ENTRYPOINT ["/entrypoint.sh"]


FROM node:20

WORKDIR /app

# Variáveis básicas
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV PYTHON=/usr/bin/python3

# Instalar TUDO que pode ser necessário
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-full \
    python3-dev \
    python3-pip \
    make \
    g++ \
    gcc \
    git \
    libnode-dev \
    libfuse2 \
    libglib2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxss1 \
    libxtst6 \
    libnss3 \
    libasound2 \
    libdrm2 \
    libgbm1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy tudo
COPY . .

# Install sem configurações especiais
RUN npm cache clean --force
RUN npm install

# Build
RUN npm run buildreact
RUN npm run compile
RUN npm run electron
RUN npm run compile-web

EXPOSE 8080

CMD ["bash", "-c", "./scripts/code-web.sh --host 0.0.0.0 --port ${PORT:-8080}"]

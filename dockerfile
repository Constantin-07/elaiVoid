# Stage 1: Build com todas as dependências
FROM node:20 AS builder

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=6144"

# Instalar TODAS as dependências de build
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    python3-distutils \
    python3-dev \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./
COPY .nvmrc ./

# Install com configurações corretas para node-gyp
RUN npm config set target_platform linux
RUN npm config set target_arch x64
RUN npm cache clean --force

# Configurar Python para node-gyp via variável de ambiente
ENV PYTHON=/usr/bin/python3

# Install dependencies com rebuild forçado
RUN npm install --build-from-source
RUN npm rebuild

# Copy source code
COPY . .

# Build application
RUN npm run buildreact
RUN npm run compile
RUN npm run electron
RUN npm run compile-web

# Stage 2: Runtime mínimo
FROM node:20-slim AS runtime

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=4096"

# Install apenas runtime dependencies
RUN apt-get update && apt-get install -y \
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

# Copy da build stage
COPY --from=builder /app .

EXPOSE 8080

CMD ["bash", "-c", "./scripts/code-web.sh --host 0.0.0.0 --port ${PORT:-8080}"]

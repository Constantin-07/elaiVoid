# STAGE 1: Build (usa seu código que funciona)
FROM node:20 as builder

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV PYTHON=/usr/bin/python3

# CORRIGIDO: Adicionadas as bibliotecas necessárias para native-keymap
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    python3-dev \
    make \
    g++ \
    pkg-config \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
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

COPY . .

# SIMPLE FIX: Comment out the problematic git commands
RUN sed -i "s/cp.execSync('git config pull.rebase merges');/\/\/ cp.execSync('git config pull.rebase merges');/" build/npm/postinstall.js
RUN sed -i "s/cp.execSync('git config blame.ignoreRevsFile .git-blame-ignore-revs');/\/\/ cp.execSync('git config blame.ignoreRevsFile .git-blame-ignore-revs');/" build/npm/postinstall.js

# Install
RUN npm install

# Build
RUN npm run buildreact
RUN npm run compile
RUN npm run electron
RUN npm run compile-web

# STAGE 2: Runtime (imagem limpa e leve)
FROM node:20-slim

WORKDIR /app

# Configurações otimizadas para runtime no Render
ENV NODE_OPTIONS="--max-old-space-size=400"
ENV PYTHON=/usr/bin/python3

# Instalar apenas dependências runtime necessárias
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
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copiar toda a estrutura necessária do build anterior
COPY --from=builder /app ./

EXPOSE 8080

# Usar exatamente o mesmo comando que funciona, mas com menos memória
CMD ["bash", "-c", "NODE_OPTIONS='--max-old-space-size=350' ./scripts/code-web.sh --host 0.0.0.0 --port ${PORT:-8080}"]

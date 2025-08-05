# Use uma imagem mais leve
FROM node:20-slim

WORKDIR /app

# Configurações de memória mais agressivas
ENV NODE_OPTIONS="--max-old-space-size=400 --optimize-for-size"
ENV PYTHON=/usr/bin/python3
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1

# Instalar apenas dependências essenciais
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
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copiar apenas arquivos necessários primeiro
COPY package*.json ./
COPY build/ ./build/
COPY scripts/ ./scripts/

# Instalar dependências com configurações otimizadas
RUN npm ci --only=production --no-optional --silent \
    && npm cache clean --force

# Copiar resto do código
COPY . .

# SIMPLE FIX: Comment out the problematic git commands
RUN sed -i "s/cp.execSync('git config pull.rebase merges');/\/\/ cp.execSync('git config pull.rebase merges');/" build/npm/postinstall.js || true
RUN sed -i "s/cp.execSync('git config blame.ignoreRevsFile .git-blame-ignore-revs');/\/\/ cp.execSync('git config blame.ignoreRevsFile .git-blame-ignore-revs');/" build/npm/postinstall.js || true

# Build em etapas separadas para economizar memória
RUN echo "Building React components..." && npm run buildreact || echo "React build failed, continuing..."

# Compilar com menos memória
RUN echo "Compiling main application..." && \
    NODE_OPTIONS="--max-old-space-size=350" npm run compile-web || \
    (echo "First compile attempt failed, trying with minimal settings..." && \
     NODE_OPTIONS="--max-old-space-size=300 --optimize-for-size" npm run compile-web)

# Limpeza após build
RUN rm -rf node_modules/.cache \
    && rm -rf .git \
    && rm -rf test \
    && rm -rf build/node_modules \
    && npm prune --production

EXPOSE 8080

# Comando otimizado para runtime
CMD ["bash", "-c", "NODE_OPTIONS='--max-old-space-size=200' ./scripts/code-web.sh --host 0.0.0.0 --port ${PORT:-8080}"]

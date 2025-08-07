# STAGE 1: Build (usa mais memória, mas é descartado)
FROM node:20 as builder

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV ELECTRON_CACHE=/app/.cache/electron

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
    git

COPY . .

# Fix git commands
RUN sed -i "s/cp.execSync('git config pull.rebase merges');/\/\/ cp.execSync('git config pull.rebase merges');/" build/npm/postinstall.js || true
RUN sed -i "s/cp.execSync('git config blame.ignoreRevsFile .git-blame-ignore-revs');/\/\/ cp.execSync('git config blame.ignoreRevsFile .git-blame-ignore-revs');/" build/npm/postinstall.js || true

# Build completo
RUN npm ci
RUN npm run download-builtin-extensions || true
RUN npm run buildreact
RUN npm run compile-web
RUN npm run electron

# Baixar todos os binários necessários
RUN if [ -f "node_modules/electron/install.js" ]; then \
        node node_modules/electron/install.js; \
    fi

# STAGE 2: Runtime (imagem final pequena)
FROM node:20-slim

WORKDIR /app

# Configurações mínimas para runtime
ENV NODE_OPTIONS="--max-old-space-size=350"
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false

# Instalar apenas dependências runtime
RUN apt-get update && apt-get install -y \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar apenas arquivos necessários do build
COPY --from=builder /app/out ./out
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/resources ./resources
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/package.json ./
COPY --from=builder /app/product.json ./
COPY --from=builder /app/.cache ./.cache

EXPOSE 8080

# Comando otimizado (binários já pré-baixados)
CMD ["bash", "-c", "NODE_OPTIONS='--max-old-space-size=200' ./scripts/code-web.sh --host 0.0.0.0 --port ${PORT:-8080} --without-connection-token"]

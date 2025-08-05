FROM node:20

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=8192"


ENV HUSKY=0
ENV CI=true

# Install required dependencies
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
	libx11-dev \
 	libxkbfile-dev \
  	pkg-config \
	libx11-dev \
 	libxkbfile-dev \
  	pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN npm config set ignore-scripts false
RUN npm install --ignore-scripts || npm install --force

RUN npm install
RUN npm run buildreact
RUN npm run compile
RUN npm run electron
RUN npm run compile-web

EXPOSE 8080

CMD ["bash", "-c", "./scripts/code-web.sh --host 0.0.0.0 --port 8080"]

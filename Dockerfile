FROM nginx:bookworm

ARG TARGETARCH

ENV NODE_VERSION=22.13.1

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    xz-utils \
    chromium \
    chromium-driver \
    libnss3 \
    libfreetype6 \
    libharfbuzz0b \
    fonts-freefont-ttf \
    bash \
    netcat-traditional \
    dumb-init \
    --no-install-recommends \
    \

    && case "$TARGETARCH" in \
    "amd64") NODE_ARCH="x64";; \
    "arm64") NODE_ARCH="arm64";; \
    "arm")   NODE_ARCH="armv7l";; \
    *) echo "Unsupported architecture: $TARGETARCH"; exit 1;; \
    esac \
    && echo "Downloading Node $NODE_VERSION for $NODE_ARCH..." \
    && curl -fsSLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz" \
    && tar -xf "node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz" \
    \

    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/share/nginx

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["nginx", "-g", "daemon off;"]
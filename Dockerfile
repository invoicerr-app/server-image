FROM nginx:bookworm

# bash, not dash: makes pipefail below apply to the SHA-check pipe.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# linux/arm/v7 dropped: Node 24 ships no linux-armv7l build.
ARG TARGETARCH

ENV NODE_VERSION=24.21.0

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# apt-get upgrade too: install alone leaves already-present packages (openssl, libssl3,
# libgnutls30) on their old, unpatched version.
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
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
    && case "$TARGETARCH" in \
    "amd64") NODE_ARCH="x64";; \
    "arm64") NODE_ARCH="arm64";; \
    *) echo "Unsupported architecture: $TARGETARCH (linux/arm/v7 is no longer built, see comment above)"; exit 1;; \
    esac \
    && echo "Downloading Node $NODE_VERSION for $NODE_ARCH..." \
    && curl -fsSLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz" \
    && curl -fsSLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt" \
    && grep " node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-$NODE_ARCH.tar.xz" SHASUMS256.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/share/nginx

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["nginx", "-g", "daemon off;"]
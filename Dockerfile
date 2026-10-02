FROM nginx:bookworm

# bash (not dash) so pipefail below actually applies: the SHA verification pipe must fail the
# build if either side of it fails, not just if sha256sum does.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# linux/arm/v7 was dropped from this image (and from invoicerr's product image) because Node.js
# stopped publishing linux-armv7l binaries starting with Node 24: upstream's own BUILDING.md lists
# armv7 as "Experimental, Downgraded as of Node.js 24", and nodejs.org/dist/v24.x.x carries no
# armv7l tarball at all. Self-hosters on a 32-bit ARM board (Raspberry Pi 2/3/Zero on the 32-bit OS)
# need to move to a 64-bit OS on the same hardware to keep using the arm64 image; 64-bit capable
# Pi 3/4/5 boards already run fine on linux/arm64.
ARG TARGETARCH

ENV NODE_VERSION=24.21.0

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# `apt-get upgrade` matters as much as `apt-get install` here: a plain install only pulls new
# versions of the packages it is asked for, it does not touch packages already satisfied by the
# base image's existing versions (openssl, libssl3, libgnutls30, ...). Measured without the
# upgrade: a same-day fresh build still carried 4 fixable CRITICAL / 57 fixable HIGH CVEs in those
# base libraries, none of them in chromium itself. With the upgrade added: 0 fixable CRITICAL, 0
# fixable HIGH on the OS packages target (Trivy 0.58.1, --severity CRITICAL,HIGH --ignore-unfixed).
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
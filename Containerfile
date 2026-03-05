ARG CONTAINER_VERSION=13.3

# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ STAGE 1: Build Prometheus from source                                    │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM golang:1.23-bookworm AS builder

# Install dependencies for building Prometheus and its UI.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    git \
    curl bzip2 \
    jq \
    make \
    nodejs \
    npm \
 && npm install -g yarn \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Resolve the latest Prometheus release tag and clone at that version.
RUN IMAGE_VERSION=$(curl -sL "https://api.github.com/repos/prometheus/prometheus/releases/latest" \
    | jq -r '.tag_name' \
    | tr -d '[:space:]') \
 && { [ -n "$IMAGE_VERSION" ] && [ "$IMAGE_VERSION" != "null" ] \
      || { echo "ERROR: failed to resolve latest prometheus release from GitHub API" >&2; exit 1; }; } \
 && echo "Building Prometheus ${IMAGE_VERSION}" \
 && git config --global advice.detachedHead false \
 && git clone --branch "${IMAGE_VERSION}" --depth 1 \
              https://github.com/prometheus/prometheus.git .

# Build the Prometheus binaries and UI assets.
RUN make assets \
 && make build

# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ STAGE 2: Final container image                                           │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM docker.io/gautada/debian:${CONTAINER_VERSION} AS container

ARG IMAGE_NAME=prometheus

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A Prometheus monitoring container based on gautada/debian."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.license="Apache-2.0"

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends jq curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=prometheus
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
COPY --from=builder /build/prometheus /usr/bin/prometheus
COPY --from=builder /build/promtool   /usr/bin/promtool

# Configuration and persistence mapping.
COPY config.yaml /etc/prometheus/config.yaml
RUN mkdir -p /mnt/volumes/data/prometheus \
 && chown -R $USER:$USER /mnt/volumes/data/prometheus

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
COPY version.sh /usr/bin/container-version
RUN chmod +x /usr/bin/container-version

# ╭――――――――――――――――――――╮
# │ LATEST             │
# ╰――――――――――――――――――――╯
COPY latest.sh /usr/bin/container-latest
RUN chmod +x /usr/bin/container-latest

# ╭――――――――――――――――――――╮
# │ HEALTH             │
# ╰――――――――――――――――――――╯
COPY appversion-check.sh /etc/container/health.d/appversion-check
RUN chmod +x /etc/container/health.d/appversion-check
COPY prometheus-running.sh /etc/container/health.d/prometheus-running
RUN chmod +x /etc/container/health.d/prometheus-running

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY prometheus.s6 /etc/services.d/prometheus/run
RUN chmod +x /etc/services.d/prometheus/run

EXPOSE 9090/tcp
VOLUME /mnt/volumes/data/prometheus

WORKDIR /home/${USER}

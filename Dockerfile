ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG CONTAINER_REVISION
ARG GDOWNLOADER_VERSION
ARG GDOWNLOADER_SHA256
ARG YTDLP_VERSION
ARG YTDLP_SHA256
ARG DENO_VERSION
ARG DENO_SHA256

WORKDIR /config

RUN add-pkg ca-certificates curl ffmpeg fonts-dejavu-core jq libxinerama1 libxkbcommon-x11-0 libxt6 libxtst6 unzip && \
    mkdir -p /opt/gdownloader /opt/gdownloader-home /defaults/gdownloader && \
    ln -s /config /opt/gdownloader-home/.gdownloader && \
    curl -fsSL -o /tmp/gdownloader.zip \
      "https://github.com/hstr0100/GDownloader/releases/download/v${GDOWNLOADER_VERSION}/gdownloader-${GDOWNLOADER_VERSION}-linux_portable_amd64.zip" && \
    echo "${GDOWNLOADER_SHA256}  /tmp/gdownloader.zip" | sha256sum -c - && \
    unzip -q /tmp/gdownloader.zip -d /opt/gdownloader && \
    rm -f /opt/gdownloader/lib/runtime/portable.lock && \
    printf '\njava-options=-Duser.home=/opt/gdownloader-home\n' >> /opt/gdownloader/lib/app/GDownloader.cfg && \
    curl -fsSL -o /usr/local/bin/yt-dlp \
      "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux" && \
    echo "${YTDLP_SHA256}  /usr/local/bin/yt-dlp" | sha256sum -c - && \
    curl -fsSL -o /tmp/deno.zip \
      "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" && \
    echo "${DENO_SHA256}  /tmp/deno.zip" | sha256sum -c - && \
    unzip -q /tmp/deno.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/yt-dlp /usr/local/bin/deno /opt/gdownloader/bin/GDownloader && \
    APP_ICON_URL=file:///opt/gdownloader/lib/GDownloader.png && \
    install_app_icon.sh "$APP_ICON_URL" && \
    { \
      echo "GDownloader ${GDOWNLOADER_VERSION}"; \
      yt-dlp --version; \
      deno --version | head -n 1; \
      ffmpeg -version | head -n 1; \
    } > /opt/gdownloader/COMPONENTS && \
    rm -f /tmp/gdownloader.zip /tmp/deno.zip

COPY defaults/config.json /defaults/gdownloader/config.json
COPY rootfs/ /
COPY LICENSE THIRD_PARTY_NOTICES.md /usr/share/doc/gdownloader-docker/

RUN chmod 0755 /startapp.sh /etc/cont-init.d/55-gdownloader.sh \
      /usr/local/lib/gdownloader/bootstrap.sh && \
    set-cont-env APP_NAME "GDownloader" && \
    set-cont-env DOCKER_IMAGE_VERSION "${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"

VOLUME ["/config", "/output"]

EXPOSE 5800

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${WEB_LISTENING_PORT:-5800}/" >/dev/null || exit 1

LABEL org.opencontainers.image.title="GDownloader" \
      org.opencontainers.image.description="Unofficial browser-accessible Docker image for GDownloader" \
      org.opencontainers.image.source="https://github.com/hstr0100/GDownloader" \
      org.opencontainers.image.version="${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"

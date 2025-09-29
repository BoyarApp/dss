# syntax=docker/dockerfile:1.4

ARG DSS_VERSION=6.2.2
ARG DSS_ASSET_URL=

FROM alpine:3.20 AS downloader

ARG DSS_VERSION
ARG DSS_ASSET_URL

WORKDIR /tmp/dss

RUN set -euo pipefail \
 && apk add --no-cache curl jq unzip \
 && if [ -n "${DSS_ASSET_URL}" ]; then \
      asset_url="${DSS_ASSET_URL}"; \
      echo "Using explicitly provided asset URL: ${asset_url}"; \
    else \
      tag_candidates="dss-${DSS_VERSION} DSS-${DSS_VERSION} v${DSS_VERSION} ${DSS_VERSION}"; \
      asset_url=""; \
      for tag in $tag_candidates; do \
        echo "Querying GitHub release tag: ${tag}"; \
        response=$(curl -fsSL "https://api.github.com/repos/esig/dss/releases/tags/${tag}" || true); \
        if [ -n "${response}" ] && echo "${response}" | jq -e '.assets | length > 0' >/dev/null 2>&1; then \
            candidate=$(echo "${response}" | jq -r '.assets[]?.browser_download_url' | grep -E 'dss-(signature|distribution).*\.(jar|zip)$' | head -n1 || true); \
            if [ -n "${candidate}" ]; then \
                asset_url="${candidate}"; \
                echo "Selected asset: ${asset_url}"; \
                break; \
            fi; \
        fi; \
      done; \
      if [ -z "${asset_url}" ]; then \
        echo "Unable to discover release asset for version ${DSS_VERSION}." >&2; \
        exit 1; \
      fi; \
    fi \
 && curl -fSL "${asset_url}" -o download.bin \
 && case "${asset_url}" in \
      *.jar) \
        mv download.bin dss-signature-webapp.jar ;; \
      *.zip) \
        unzip -q download.bin \
        && jar_path=$(find . -name 'dss-signature-webapp*.jar' -print -quit) \
        && if [ -z "${jar_path}" ]; then \
             echo "No dss-signature-webapp jar found inside archive" >&2 \
             && exit 1; \
           fi \
        && mv "${jar_path}" dss-signature-webapp.jar ;; \
      *) \
        echo "Unsupported asset format: ${asset_url}" >&2 \
        && exit 1 ;; \
    esac

FROM eclipse-temurin:17-jre AS runtime

ARG DSS_VERSION

ENV JAVA_OPTS="-Xms512m -Xmx1024m" \
    DSS_VERSION=${DSS_VERSION}

RUN useradd -r -m dss

WORKDIR /opt/dss

COPY --from=downloader /tmp/dss/dss-signature-webapp.jar ./dss-signature-webapp.jar
COPY config/ ./config/

RUN chown -R dss:dss /opt/dss

USER dss

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -Dspring.config.additional-location=file:/opt/dss/config/ -jar /opt/dss/dss-signature-webapp.jar"]

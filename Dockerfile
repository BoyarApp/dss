# syntax=docker/dockerfile:1.4

ARG DSS_VERSION=6.2.2

FROM alpine:3.20 AS downloader

ARG DSS_VERSION

WORKDIR /tmp/dss

RUN set -euo pipefail \
 && apk add --no-cache curl unzip \
 && release_dirs="dss-${DSS_VERSION} DSS-${DSS_VERSION}" \
 && jar_downloaded=false \
 && for dir in $release_dirs; do \
      base_url="https://github.com/esig/dss/releases/download/${dir}"; \
      for asset in \
          "dss-signature-webapp-${DSS_VERSION}-exec.jar" \
          "dss-signature-webapp-${DSS_VERSION}.jar" \
          "dss-signature-webapp-${DSS_VERSION}.zip" \
          "dss-distribution-${DSS_VERSION}.zip" \
          "dss-${DSS_VERSION}.zip"; do \
        echo "Attempting to fetch ${base_url}/${asset}"; \
        if curl -fSL "${base_url}/${asset}" -o download.bin; then \
            case "${asset}" in \
              *.jar) \
                mv download.bin dss-signature-webapp.jar; \
                jar_downloaded=true; \
                break 2 ;; \
              *.zip) \
                unzip -q download.bin; \
                jar_path=$(find . -name 'dss-signature-webapp*.jar' -print -quit); \
                if [ -n "${jar_path}" ]; then \
                    mv "${jar_path}" dss-signature-webapp.jar; \
                    jar_downloaded=true; \
                    break 2; \
                fi ;; \
            esac; \
        fi; \
      done; \
    done \
 && if [ "${jar_downloaded}" != "true" ]; then \
      echo "Unable to obtain dss-signature-webapp artifact for version ${DSS_VERSION}" >&2; \
      exit 1; \
    fi

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

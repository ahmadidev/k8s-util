FROM alpine:3 AS utils

ARG HELM_VERSION=3.9.4
ENV HELM_BASE_URL="https://get.helm.sh"
RUN case `uname -m` in \
        x86_64) ARCH=amd64; ;; \
        armv7l) ARCH=arm; ;; \
        aarch64) ARCH=arm64; ;; \
        ppc64le) ARCH=ppc64le; ;; \
        s390x) ARCH=s390x; ;; \
        *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac && \
    wget ${HELM_BASE_URL}/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz -O - | tar -xz && \
    mv linux-${ARCH}/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-${ARCH}

# https://github.com/bitnami/containers/blob/main/bitnami/kubectl/1.26/debian-11/Dockerfile
FROM bitnami/kubectl:1.26-debian-11
LABEL org.opencontainers.image.source=https://github.com/ahmadidev/k8s-util
LABEL org.opencontainers.image.description="A docker image based on bitnami kubectl with helm and gettext package"
COPY --from=utils /usr/bin/helm /usr/bin/helm
USER 0
RUN apt-get update
RUN install_packages gettext
USER 1001

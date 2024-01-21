FROM fedora:latest AS BUILD
ARG KERNEL_VERSION

COPY custom.repo /etc/yum.repos.d/

RUN set -x \
  \
  && dnf install -y --setopt=install_weak_deps=False \
    nvidia-driver-cuda-libs \
    nvidia-driver-NvFBCOpenGL \
    git-core

RUN set -x \
  # patch nvidia driver #
  && git clone https://github.com/keylase/nvidia-patch.git nvidia-patch \
  # script forces check on nvidia-smi even when passing in a driver version. hack around it
  && touch /usr/bin/nvidia-smi \
  && ./nvidia-patch/patch.sh -d $(rpm -q --queryformat "%{VERSION}" nvidia-driver-cuda-libs) \
  && ./nvidia-patch/patch-fbc.sh -d $(rpm -q --queryformat "%{VERSION}" nvidia-driver-cuda-libs) \
  && rm -r \
    nvidia-patch \
    /opt/nvidia \
  && mkdir -p /build \
  && mv /usr/lib64/libnvidia-fbc.* /build \
  && mv /usr/lib64/libnvidia-encode.* /build \
  \
  # missing symlinks #
  && cd /usr/lib64 \
  && ln -s \
    libnvidia-vulkan-producer.so.$(rpm -q --queryformat "%{VERSION}" nvidia-driver-cuda-libs) \
    libnvidia-vulkan-producer.so \
  && mv libnvidia-vulkan-producer.so /build

FROM alpine:latest

COPY --from=BUILD /build /opt/lib64
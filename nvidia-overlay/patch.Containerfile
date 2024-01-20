FROM fedora:latest AS BUILD
ARG KERNEL_VERSION

COPY custom.repo /etc/yum.repos.d/
VOLUME /opt

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
  && mkdir -p /opt/lib64 \
  && mv /usr/lib64/libnvidia-fbc.* /opt/lib64 \
  && mv /usr/lib64/libnvidia-encode.* /opt/lib64 \
  \
  # missing symlinks #
  && cd /usr/lib64 \
  && ln -s \
    libnvidia-vulkan-producer.so.$(rpm -q --queryformat "%{VERSION}" nvidia-driver-cuda-libs) \
    libnvidia-vulkan-producer.so \
  && mv libnvidia-vulkan-producer.so /opt/lib64
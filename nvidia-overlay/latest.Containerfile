ARG FEDORA_VERSION=39

FROM registry.fedoraproject.org/fedora-minimal:$FEDORA_VERSION AS BUILD
ARG KERNEL_RELEASE
ARG DRIVER_VERSION

COPY custom.repo /etc/yum.repos.d/

RUN set -x \
  \
  && echo 'exclude=*.i386 *.i686' >> /etc/dnf.conf \
  && microdnf install -y --setopt=install_weak_deps=False \
    kernel-devel-$KERNEL_RELEASE \
    kmod-nvidia-latest-dkms-$DRIVER_VERSION \
  && microdnf clean all \
  && rm -rf \
    /var/cache \
    /var/log/*

RUN set -x \
  \
  && dkms build -m nvidia/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-latest-dkms) \
    -k $KERNEL_RELEASE \
    -a ${KERNEL_RELEASE##*.} \
    --no-depmod \
    --kernelsourcedir /usr/src/kernels/$KERNEL_RELEASE \
  && mkdir -p /build \
  && cp /var/lib/dkms/nvidia/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-latest-dkms)/$KERNEL_RELEASE/${KERNEL_RELEASE##*.}/module/* /build

FROM alpine:latest
ARG KERNEL_RELEASE

COPY --from=BUILD /build /opt/lib/modules/$KERNEL_RELEASE/kernel/drivers/video

RUN set -x \
  \
  && apk add --no-cache \
    kmod \
  && depmod -b /opt $KERNEL_RELEASE
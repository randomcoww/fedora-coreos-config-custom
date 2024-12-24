ARG FEDORA_VERSION=latest
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
  && KERNEL_PATH=$(rpm -q --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-devel) \
  && DRIVER_VERSION=$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-latest-dkms) \
  && dkms build \
    -m nvidia/$DRIVER_VERSION \
    -k $KERNEL_PATH \
    -a $(arch) \
    --no-depmod \
    --kernelsourcedir /usr/src/kernels/$KERNEL_PATH \
  && mkdir -p /opt/lib/modules/$KERNEL_PATH/kernel/drivers/video \
  && cp /var/lib/dkms/nvidia/$DRIVER_VERSION/$KERNEL_PATH/$(arch)/module/* \
    /opt/lib/modules/$KERNEL_PATH/kernel/drivers/video \
  && depmod -b /opt $KERNEL_PATH

FROM alpine:latest

COPY --from=BUILD /opt/lib/modules /opt/lib/modules
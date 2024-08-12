ARG FEDORA_VERSION

FROM fedora:$FEDORA_VERSION AS BUILD
ARG KERNEL_VERSION
ARG DRIVER_VERSION

COPY custom.repo /etc/yum.repos.d/

RUN set -x \
  \
  && dnf install -y --setopt=install_weak_deps=False \
    kernel-devel-$KERNEL_VERSION \
    kmod-nvidia-open-dkms-$DRIVER_VERSION

RUN set -x \
  \
  && dkms build -m nvidia-open/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-open-dkms) \
    -k $KERNEL_VERSION \
    -a ${KERNEL_VERSION##*.} \
    --no-depmod \
    --kernelsourcedir /usr/src/kernels/$KERNEL_VERSION \
  && mkdir -p /build \
  && cp /var/lib/dkms/nvidia-open/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-open-dkms)/$KERNEL_VERSION/${KERNEL_VERSION##*.}/module/* /build

FROM alpine:latest
ARG KERNEL_VERSION

COPY --from=BUILD /build /opt/lib/modules/$KERNEL_VERSION/kernel/drivers/video

RUN set -x \
  \
  && apk add --no-cache \
    kmod \
  && depmod -b /opt $KERNEL_VERSION
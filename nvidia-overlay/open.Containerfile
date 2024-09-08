FROM fedora:latest AS BUILD
ARG KERNEL_RELEASE
ARG DRIVER_VERSION

COPY custom.repo /etc/yum.repos.d/

RUN set -x \
  \
  && dnf install -y --setopt=install_weak_deps=False \
    kernel-devel-$KERNEL_RELEASE \
    kmod-nvidia-open-dkms-$DRIVER_VERSION

RUN set -x \
  \
  && dkms build -m nvidia-open/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-open-dkms) \
    -k $KERNEL_RELEASE \
    -a ${KERNEL_RELEASE##*.} \
    --no-depmod \
    --kernelsourcedir /usr/src/kernels/$KERNEL_RELEASE \
  && mkdir -p /build \
  && cp /var/lib/dkms/nvidia-open/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-open-dkms)/$KERNEL_RELEASE/${KERNEL_RELEASE##*.}/module/* /build

FROM alpine:latest
ARG KERNEL_RELEASE

COPY --from=BUILD /build /opt/lib/modules/$KERNEL_RELEASE/kernel/drivers/video

RUN set -x \
  \
  && apk add --no-cache \
    kmod \
  && depmod -b /opt $KERNEL_RELEASE
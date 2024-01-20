FROM fedora:latest AS BUILD
ARG KERNEL_VERSION
ARG DRIVER_VERSION

COPY custom.repo /etc/yum.repos.d/
VOLUME /opt

RUN set -x \
  \
  && dnf install -y --setopt=install_weak_deps=False \
    kernel-devel-$KERNEL_VERSION \
    https://developer.download.nvidia.com/compute/cuda/repos/fedora37/$(arch)/kmod-nvidia-open-dkms-$DRIVER_VERSION-1.fc37.$(arch).rpm
    # kmod-nvidia-open-dkms-$DRIVER_VERSION

RUN set -x \
  \
  && dkms build -m nvidia-open/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-open-dkms) \
    -k $KERNEL_VERSION \
    -a ${KERNEL_VERSION##*.} \
    --no-depmod \
    --kernelsourcedir /usr/src/kernels/$KERNEL_VERSION

RUN set -x \
  \
  && mkdir -p /opt/lib/modules/$KERNEL_VERSION/kernel/drivers/video \
  && cp /var/lib/dkms/nvidia-open/$(rpm -q --queryformat "%{VERSION}" kmod-nvidia-open-dkms)/$KERNEL_VERSION/${KERNEL_VERSION##*.}/module/* \
    /opt/lib/modules/$KERNEL_VERSION/kernel/drivers/video \
  && depmod -b /opt $KERNEL_VERSION
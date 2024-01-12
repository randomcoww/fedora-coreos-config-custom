FROM fedora:latest AS BUILD

ARG KERNEL_VERSION=6.4.12-200.fc38.x86_64
ARG DRIVER_VERSION=535.98

RUN set -x \
  \
  && dnf install -y \
    kernel-devel-$KERNEL_VERSION \
    kmod \
    g++ \
    git-core \
  \
  # build everything under /opt
  && curl -o nvidia.run \
    -LO https://download.nvidia.com/XFree86/Linux-${KERNEL_VERSION##*.}/$DRIVER_VERSION/NVIDIA-Linux-${KERNEL_VERSION##*.}-$DRIVER_VERSION.run \
  && chmod +x nvidia.run \
  && ./nvidia.run \
    --skip-module-unload \
    --silent \
    --x-prefix=/opt/usr \
    --x-module-path=/opt/usr/lib64/xorg/modules \
    --x-library-path=/opt/usr/lib64 \
    --x-sysconfig-path=/opt/usr/share/X11/xorg.conf.d \
    --opengl-prefix=/opt/usr \
    --opengl-libdir=lib64 \
    --wine-prefix=/opt/usr \
    --installer-prefix=/opt/usr \
    --utility-prefix=/opt/usr \
    --utility-libdir=lib64 \
    --xdg-data-dir=/opt/usr/share \
    --documentation-prefix=/opt/usr \
    --application-profile-path=/opt/usr/share/nvidia \
    --kernel-source-path=/usr/src/kernels/$KERNEL_VERSION \
    --kernel-install-path=/opt/usr/lib/modules/$KERNEL_VERSION/kernel/drivers/video \
    --no-rpms \
    --no-backup \
    --no-recursion \
    --no-x-check \
    --no-nouveau-check \
    --no-distro-scripts \
    --no-dkms \
    --no-check-for-alternate-installs \
    --glvnd-egl-config-path=/opt/usr/share/glvnd/egl_vendor.d \
    --egl-external-platform-config-path=/opt/usr/share/egl/egl_external_platform.d \
    --skip-depmod \
    --no-systemd \
    -j "$(getconf _NPROCESSORS_ONLN)" \
  \
  # finish moving things where fedora expects them relative to /opt
  && mv /opt/usr/lib/gbm /opt/usr/lib64 \
  && mkdir -p \
    /opt/usr/lib/firmware \
    /opt/usr/share \
    /opt/etc \
  \
  && cp -r /usr/lib/nvidia/. /opt/usr/lib64/nvidia \
  && cp -r /usr/lib/firmware/nvidia/. /opt/usr/lib/firmware/nvidia \
  && cp -r /usr/share/nvidia/. /opt/usr/share/nvidia \
  && cp -r /etc/vulkan /etc/OpenCL /opt/etc \
  # delete non nvidia specific libraries
  && rm -f \
    /opt/usr/lib64/libEGL.* \
    /opt/usr/lib64/libGL.* \
    /opt/usr/lib64/libGLdispatch.* \
    /opt/usr/lib64/libGLESv1_CM.* \
    /opt/usr/lib64/libGLESv2.* \
    /opt/usr/lib64/libGLX.* \
    /opt/usr/lib64/libGLdispatch.* \
    /opt/usr/lib64/libOpenCL.* \
    /opt/usr/lib64/libOpenGL.* \
  \
  # patch libnvidia-encode and libnvidia-fbc libraries
  && ln -s /opt/usr/lib64/* /usr/lib64/ \
  && ln -s /opt/usr/bin/* /usr/bin \
  && git clone https://github.com/keylase/nvidia-patch.git nvidia-patch \
  && ./nvidia-patch/patch.sh -d $DRIVER_VERSION \
  && ./nvidia-patch/patch-fbc.sh -d $DRIVER_VERSION \
  && rm -r \
    nvidia-patch \
    /opt/nvidia

FROM alpine:edge

COPY --from=BUILD /opt /opt
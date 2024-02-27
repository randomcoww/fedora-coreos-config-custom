## Custom Fedora CoreOS builds

Add and remove components to support:

* Bare metal live ISO and PXE boot only
* systemd-networkd instead of NetworkManager

COSA upstream with full instructions: https://github.com/coreos/coreos-assembler

* CoreOS packages: https://github.com/coreos/fedora-coreos-config.git
* Silverblue packages: https://pagure.io/workstation-ostree-config.git

### Checkout

```bash
git clone --recurse-submodules git@github.com:randomcoww/fedora-coreos-config-custom.git
cd fedora-coreos-config-custom
git submodule update --remote
```

### Update COSA image

```bash
mkdir -p tmp
TMPDIR=$(pwd)/tmp podman pull quay.io/coreos-assembler/coreos-assembler:latest
```

```bash
cosa() {
   env | grep COREOS_ASSEMBLER
   set -x
   podman --tmpdir ${PWD}/tmp run --rm -ti --security-opt label=disable --privileged -w /srv \
      --uidmap=$(id -u):0:1 --uidmap=0:1:$(id -u) --uidmap $(( $(id -u) + 1 )):$(( $(id -u) + 1 )):55536 \
      -v ${PWD}:/srv/ --device /dev/kvm --device /dev/fuse \
      --tmpfs /tmp --name cosa-coreos \
      ${COREOS_ASSEMBLER_CONFIG_GIT:+-v $COREOS_ASSEMBLER_CONFIG_GIT:/srv/src/config/:ro} \
      ${COREOS_ASSEMBLER_GIT:+-v $COREOS_ASSEMBLER_GIT/src/:/usr/lib/coreos-assembler/:ro} \
      ${COREOS_ASSEMBLER_ADD_CERTS:+-v=/etc/pki/ca-trust:/etc/pki/ca-trust:ro} \
      ${COREOS_ASSEMBLER_CONTAINER_RUNTIME_ARGS} \
      ${COREOS_ASSEMBLER_CONTAINER:-quay.io/coreos-assembler/coreos-assembler:latest} "$@"
   rc=$?; set +x; return $rc
}
```

### Fetch sources

Run one of:

```bash
VARIANT=coreos
VARIANT=silverblue-nvidia
VARIANT=silverblue-chromebook
```

```bash
BUILD_PATH=$HOME/$VARIANT
mkdir -p $BUILD_PATH && cd $BUILD_PATH

cosa init -V $VARIANT --force https://github.com/randomcoww/fedora-coreos-config-custom.git
sudo chown $(stat -c %u .):$(stat -c %g .) $(pwd)/tmp
```

### Build Nvidia kernel modules into overlay

Kernel releases https://bodhi.fedoraproject.org/updates/?search=&packages=kernel&status=stable&releases=F39

CUDA driver releases https://developer.download.nvidia.com/compute/cuda/repos/fedora37/x86_64/

```bash
KERNEL_VERSION=6.7.5-200.fc39.x86_64
DRIVER_VERSION=550.54.14
TAG=ghcr.io/randomcoww/nvidia-kmod:$KERNEL_VERSION-$DRIVER_VERSION

mkdir -p tmp
TMPDIR=$(pwd)/tmp podman build \
  --build-arg KERNEL_VERSION=$KERNEL_VERSION \
  --build-arg DRIVER_VERSION=$DRIVER_VERSION \
  -f src/config/nvidia-overlay/kmod.Containerfile \
  -t $TAG

podman run --rm \
  -v $(pwd)/src/config/overlay.d/02nvidia/usr:/mnt \
  $TAG cp -r /opt/. /mnt
```

### Populate hacks for Chromebook into overlay

- https://github.com/WeirdTreeThing/chromebook-linux-audio
- https://github.com/WeirdTreeThing/chromebook-ucm-conf

```bash
mkdir -p tmp
TMPDIR=$(pwd)/tmp podman build \
  -f src/config/chromebook-overlay/Containerfile \
  -t chromebook-overlay

sudo mkdir -p src/config/overlay.d/03chromebook
sudo chown $(stat -c %u .):$(stat -c %g .) src/config/overlay.d/03chromebook

podman run --rm \
  -v $(pwd)/src/config/overlay.d/03chromebook:/mnt \
  chromebook-overlay cp -r /opt/. /mnt
```

### Run build

```bash
cosa clean && \
cosa fetch && \
cosa build metal4k && \
cosa buildextend-metal && \
cosa buildextend-live
```

### Upload images for PXE boot

```bash
mc cp -r --disable-multipart builds/latest/x86_64/fedora-*-live* m/boot/
```

### Write ISO image

```bash
export HOST=de-0

coreos-installer iso ignition embed \
  -i $HOME/project/homelab/output/ignition/$HOST.ign \
  -o $HOME/$HOST.iso \
  builds/latest/x86_64/fedora-*-live.x86_64.iso
```

### Update backup boot disk with current PXE boot image

```bash
export IMAGE=$(xargs -n1 -a /proc/cmdline | grep ^fedora | sed 's/-kernel-x86_64$//')
export IGNITION_URL=$(xargs -n1 -a /proc/cmdline | grep ^ignition.config.url= | sed 's/ignition.config.url=//')
export DISK=/dev/$(lsblk -ndo pkname /dev/disk/by-label/fedora-*)

echo image=$IMAGE
echo ignition-url=$IGNITION_URL
echo disk=$DISK
sudo lsof $DISK
```

```bash
curl https://minio.fuzzybunny.win/boot/$IMAGE.x86_64.iso --output coreos.iso
curl $IGNITION_URL | coreos-installer iso ignition embed coreos.iso

sudo dd if=coreos.iso of=$DISK bs=4M
sync
rm coreos.iso
```
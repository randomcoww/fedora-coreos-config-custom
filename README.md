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
cosa() {
   env | grep COREOS_ASSEMBLER
   set -x
   podman run --rm -ti --security-opt label=disable --privileged -w /srv \
      --uidmap=$(id -u):0:1 --uidmap=0:1:$(id -u) --uidmap $(( $(id -u) + 1 )):$(( $(id -u) + 1 )):55536 \
      -v ${PWD}:/srv/ --device /dev/kvm --device /dev/fuse \
      --tmpfs /tmp --name cosa-coreos \
      --env COSA_SUPERMIN_MEMORY=4096 \
      ${COREOS_ASSEMBLER_CONFIG_GIT:+-v $COREOS_ASSEMBLER_CONFIG_GIT:/srv/src/config/:ro} \
      ${COREOS_ASSEMBLER_GIT:+-v $COREOS_ASSEMBLER_GIT/src/:/usr/lib/coreos-assembler/:ro} \
      ${COREOS_ASSEMBLER_ADD_CERTS:+-v=/etc/pki/ca-trust:/etc/pki/ca-trust:ro} \
      ${COREOS_ASSEMBLER_CONTAINER_RUNTIME_ARGS} \
      ${COREOS_ASSEMBLER_CONTAINER:-quay.io/coreos-assembler/coreos-assembler:latest} "$@"
   rc=$?; set +x; return $rc
}
```

### Fetch sources

```bash
VARIANT=coreos
BUILD_PATH=$HOME/$VARIANT
mkdir -p $BUILD_PATH && cd $BUILD_PATH

cosa init -V $VARIANT --force https://github.com/randomcoww/fedora-coreos-config-custom.git
sudo chown $(stat -c %u .):$(stat -c %g .) $(pwd)/tmp
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
mc cp -r builds/latest/x86_64/fedora-*-live* m/data-boot/
```

### Write ISO image with ignition example

Points to ignition generated with https://github.com/randomcoww/homelab

```bash
export HOST=de-0

coreos-installer iso ignition embed \
  -i $HOME/projects/homelab/output/ignition/$HOST.ign \
  -o $HOME/$HOST.iso \
  builds/latest/x86_64/fedora-*-live.x86_64.iso
```

### Modify kargs example

```bash
coreos-installer iso kargs modify \
  -a systemd.unit=multi-user.target \
  -o $HOME/$HOST-server.iso \
  $HOME/$HOST.iso
```

### Update backup boot disk with current PXE boot image

```bash
export IMAGE_URL=$(xargs -n1 -a /proc/cmdline | grep ^coreos.live.rootfs_url= | sed -r 's/coreos.live.rootfs_url=(.*)-rootfs(.*)\.img$/\1\2.iso/')
export IGNITION_URL=$(xargs -n1 -a /proc/cmdline | grep ^ignition.config.url= | sed 's/ignition.config.url=//')
export DISK=/dev/$(lsblk -ndo pkname /dev/disk/by-label/fedora-*)

echo image-url=$IMAGE_URL
echo ignition-url=$IGNITION_URL
echo disk=$DISK
sudo lsof $DISK
```

```bash
curl $IMAGE_URL --output coreos.iso
curl $IGNITION_URL | coreos-installer iso ignition embed coreos.iso

sudo dd if=coreos.iso of=$DISK bs=4M
sync
rm coreos.iso
```

## Custom Fedora CoreOS builds

Add and remove components to support:

* Bare metal live ISO and PXE boot only
* systemd-networkd instead of NetworkManager

COSA upstream with full instructions: https://github.com/coreos/coreos-assembler

* CoreOS packages: https://github.com/coreos/fedora-coreos-config.git
* Silverblue packages: https://pagure.io/workstation-ostree-config.git

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

```bash
BUILD_PATH=$HOME/cosa
mkdir -p $BUILD_PATH && cd $BUILD_PATH

cosa init --force https://github.com/randomcoww/fedora-coreos-config-custom.git
```

### Render manifests

```bash
cd $BUILD_PATH/src/config
```

```bash
tw() {
  set -x
  podman run -it --rm --security-opt label=disable \
    --entrypoint='' \
    -v $(pwd):$(pwd) \
    -w $(pwd) \
    --net=host \
    docker.io/hashicorp/terraform:1.4.7 "$@"
  rc=$?; set +x; return $rc
}
```

Run one of

```bash
tw terraform -chdir=tf-coreos init && \
tw terraform -chdir=tf-coreos apply

tw terraform -chdir=tf-silverblue-nvidia init && \
tw terraform -chdir=tf-silverblue-nvidia apply

tw terraform -chdir=tf-silverblue-chromebook init && \
tw terraform -chdir=tf-silverblue-chromebook apply
```

### Build Nvidia kernel modules

```bash
KERNEL_VERSION=6.6.9-200.fc39.x86_64
DRIVER_VERSION=545.23.08
TAG=ghcr.io/randomcoww/nvidia-kmod:$KERNEL_VERSION

mkdir -p tmp
TMPDIR=$(pwd)/tmp podman build \
  --build-arg KERNEL_VERSION=$KERNEL_VERSION \
  --build-arg DRIVER_VERSION=$DRIVER_VERSION \
  -f nvidia-overlay/kmod.Containerfile \
  -t $TAG

mkdir -p usr
podman run --rm \
  -v $(pwd)/usr:/mnt \
  $TAG cp -r /opt/. /mnt

sudo cp -a usr/. $BUILD_PATH/src/config/overlay.d/02nvidia/usr/
```

### Hacks for Chromebook

Copy files for https://github.com/WeirdTreeThing/chromebook-linux-audio

```bash
git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git

sudo cp -a \
  chromebook-linux-audio/conf/sof/tplg/. \
  $BUILD_PATH/src/config/overlay.d/03chromebook/usr/lib/firmware/intel/sof-tplg/

sudo cp -a \
  chromebook-linux-audio/conf/common/. \
  $BUILD_PATH/src/config/overlay.d/03chromebook/etc/wireplumber/main.lua.d/

git clone https://github.com/WeirdTreeThing/chromebook-ucm-conf.git

sudo cp -a \
  chromebook-ucm-conf/common \
  chromebook-ucm-conf/codecs \
  chromebook-ucm-conf/platforms \
  $BUILD_PATH/src/config/overlay.d/03chromebook/usr/share/alsa/ucm2/

sudo cp -a \
  chromebook-ucm-conf/adl/. \
  chromebook-ucm-conf/sof-rt5682 \
  chromebook-ucm-conf/sof-cs42l42 \
  $BUILD_PATH/src/config/overlay.d/03chromebook/usr/share/alsa/ucm2/conf.d/
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

sudo coreos-installer iso ignition embed \
  -i $HOME/project/homelab/output/ignition/$HOST.ign \
  -o $HOST.iso \
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
curl http://m.fuzzybunny.win/boot/$IMAGE.x86_64.iso --output coreos.iso
curl $IGNITION_URL | coreos-installer iso ignition embed coreos.iso

sudo dd if=coreos.iso of=$DISK bs=4M
sync
rm coreos.iso
```

```bash
curl $IGNITION_URL | sudo coreos-installer iso ignition embed $DISK --force
```
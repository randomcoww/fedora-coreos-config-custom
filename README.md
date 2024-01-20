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
```

### Build Nvidia kernel modules

Kernel releases https://bodhi.fedoraproject.org/updates/?search=&packages=kernel&status=stable&releases=F39

CUDA driver releases https://developer.download.nvidia.com/compute/cuda/repos/fedora37/x86_64/

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

### Run build

```bash
cd $BUILD_PATH

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

### Populate hacks for Chromebook into overlay

Copy files for https://github.com/WeirdTreeThing/chromebook-linux-audio

```bash
OVERLAY_PATH=overlay.d/03chromebook

git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git
git clone https://github.com/WeirdTreeThing/chromebook-ucm-conf.git

mkdir -p $OVERLAY_PATH/usr/lib/firmware/intel/sof-tplg/
cp -a \
  chromebook-linux-audio/conf/sof/tplg/. \
  $OVERLAY_PATH/usr/lib/firmware/intel/sof-tplg/

mkdir -p $OVERLAY_PATH/etc/wireplumber/main.lua.d/
cp -a \
  chromebook-linux-audio/conf/common/. \
  $OVERLAY_PATH/etc/wireplumber/main.lua.d/

mkdir -p $OVERLAY_PATH/usr/share/alsa/ucm2/
cp -a \
  chromebook-ucm-conf/common \
  chromebook-ucm-conf/codecs \
  chromebook-ucm-conf/platforms \
  $OVERLAY_PATH/usr/share/alsa/ucm2/

mkdir -p $OVERLAY_PATH/usr/share/alsa/ucm2/conf.d/
cp -a \
  chromebook-ucm-conf/adl/. \
  chromebook-ucm-conf/sof-rt5682 \
  chromebook-ucm-conf/sof-cs42l42 \
  $OVERLAY_PATH/usr/share/alsa/ucm2/conf.d/

mkdir -p $OVERLAY_PATH/usr/lib/firmware/intel/sof-tplg
for t in \
cs35l41 max98357a-rt5682-4ch max98357a-rt5682 max98360a-cs42l42 max98360a-nau8825 \
max98360a-rt5682-2way max98360a-rt5682-4ch max98360a-rt5682 max98373-nau8825 \
max98390-rt5682 max98390-ssp2-rt5682-ssp0 nau8825 rt1019-nau8825 rt1019-rt5682 rt5682 \
rt711 sdw-max98373-rt5682;
do
  ln -sf sof-adl-${t}.tplg.xz \
    $OVERLAY_PATH/usr/lib/firmware/intel/sof-tplg/sof-rpl-${t}.tplg.xz;
done
```
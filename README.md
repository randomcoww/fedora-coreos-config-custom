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

### Set build variant

```bash
export VARIANT=coreos
```

or

```bash
export VARIANT=silverblue
```

### Fetch sources

```bash
mkdir -p $HOME/$VARIANT
cd $HOME/$VARIANT

cosa init -V $VARIANT --force https://github.com/randomcoww/fedora-coreos-config-custom.git 
```

### Build Nvidia kernel modules

```bash
KERNEL_VERSION=6.6.9-200.fc39.x86_64
DRIVER_VERSION=545.23.08
TAG=ghcr.io/randomcoww/nvidia-kmod:$KERNEL_VERSION
BUILD_PATH=$HOME/$VARIANT

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

### Patched Nvidia libs

```bash
TAG=ghcr.io/randomcoww/nvidia-patch:latest
BUILD_PATH=$HOME/$VARIANT

mkdir -p tmp
TMPDIR=$(pwd)/tmp podman build \
  -f nvidia-overlay/patch.Containerfile \
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
git clone https://github.com/WeirdTreeThing/chromebook-ucm-conf.git

sudo cp -a \
  chromebook-ucm-conf/adl/. \
  $HOME/$VARIANT/src/config/overlay.d/03chromebook/usr/share/alsa/ucm2/conf.d/

sudo cp -r \
  chromebook-ucm-conf/common \
  chromebook-ucm-conf/codecs \
  chromebook-ucm-conf/platforms \
  chromebook-ucm-conf/sof-rt5682 \
  chromebook-ucm-conf/sof-cs42l42 \
  $HOME/$VARIANT/src/config/overlay.d/03chromebook/usr/share/alsa/ucm2/

git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git

sudo cp -r \
  chromebook-linux-audio/conf/sof/tplg/* \
  $HOME/$VARIANT/src/config/overlay.d/03chromebook/usr/lib/firmware/intel/sof-tplg/
```

Enable chromebook packages in `manifest-silverblue.yaml`

```diff
@@ -3,8 +3,8 @@ include:
   - vrrp.yaml
   - kubernetes.yaml
   - desktop.yaml
-  - nvidia.yaml
-  # - chromebook.yaml
+  # - nvidia.yaml
+  - chromebook.yaml

 rojig:
   license: MIT
@@ -21,5 +21,5 @@ exclude-packages:
   # - python3-libs
   # - perl-interpreter
   # - grubby
-  - NetworkManager
+  # - NetworkManager
   # - NetworkManager-libnm
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
mc cp -r --disable-multipart builds/latest/x86_64/fedora-$VARIANT-*-live* m/boot/
```

### Write ISO image

```bash
export HOST=de-0

sudo coreos-installer iso ignition embed \
  -i $HOME/project/homelab/output/ignition/$HOST.ign \
  -o $HOST.iso \
  builds/latest/x86_64/fedora-$VARIANT-*-live.x86_64.iso
```

Append kargs for Chromebook

```bash
sudo coreos-installer iso kargs modify $HOST.iso \
  -a pci=nommconf \
  -a snd-intel-dspcfg.dsp_driver=3
```

Append kargs for server

```bash
sudo coreos-installer iso kargs modify $HOST.iso \
  -a systemd.unit=multi-user.target
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

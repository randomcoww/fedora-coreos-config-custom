## Custom Fedora CoreOS builds

Add and remove components to support:

* Bare metal live ISO and PXE boot only
* systemd-networkd instead of NetworkManager

COSA upstream with full instructions: https://github.com/coreos/coreos-assembler

* CoreOS packages: https://github.com/coreos/fedora-coreos-config.git
* Silverblue packages: https://pagure.io/workstation-ostree-config.git

### Update COSA image

```bash
mkdir -p build
TMPDIR=$(pwd)/build podman pull quay.io/coreos-assembler/coreos-assembler:latest
```

```bash
cosa() {
   env | grep COREOS_ASSEMBLER
   set -x
   podman --tmpdir ${PWD}/tmp run --rm -ti --security-opt label=disable --privileged --net host -w /srv \
      --uidmap=$(id -u):0:1 --uidmap=0:1:$(id -u) --uidmap $(( $(id -u) + 1 )):$(( $(id -u) + 1 )):55536 \
      -v ${PWD}:/srv/ --device /dev/kvm --device /dev/fuse \
      --tmpfs /tmp --name cosa-coreos \
      ${COREOS_ASSEMBLER_CONFIG_GIT:+-v $COREOS_ASSEMBLER_CONFIG_GIT:/srv/src/config/:ro} \
      ${COREOS_ASSEMBLER_GIT:+-v $COREOS_ASSEMBLER_GIT/src/:/usr/lib/coreos-assembler/:ro} \
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

### Run build

```bash
cosa init -V $VARIANT --force https://github.com/randomcoww/fedora-coreos-config-custom.git 
```

```bash
cosa clean && \
cosa fetch && \
cosa build metal4k && \
cosa buildextend-metal && \
cosa buildextend-live
```

### Upload images for PXE boot

```bash
mc cp -r builds/latest/x86_64/fedora-$VARIANT-*-live* minio/boot/
```

### Write ISO image

```bash
HOST=gw-0

sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/$HOST.ign \
  -o $HOST.iso \
  builds/latest/x86_64/fedora-$VARIANT-*-live.x86_64.iso
```

### Write to disk

```bash
HOST=gw-0
DISK=/dev/sda

sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/$HOST.ign \
  $DISK --force
```

### Update custom repo

Add package file to `repo/fedora`

Update metadata:

```bash
podman run -it --rm -v $(pwd):/repo fedora

dnf install -y createrepo
createrepo repo/fedora
```
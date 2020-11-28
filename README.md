# fedora-silverblue-custom

#### Build image

From upstream: https://github.com/coreos/coreos-assembler

```bash
cosa() {
   env | grep COREOS_ASSEMBLER
   set -x
   podman run --rm -ti --security-opt label=disable --privileged -w /srv                            \
              --uidmap=10000:0:1 --uidmap=0:1:10000 --uidmap 10001:10001:55536                      \
              -v ${PWD}:/srv/ --device /dev/kvm --device /dev/fuse                                  \
              --tmpfs /tmp -v /var/tmp:/var/tmp --name cosa-silverblue                              \
              ${COREOS_ASSEMBLER_CONFIG_GIT:+-v $COREOS_ASSEMBLER_CONFIG_GIT:/srv/src/config/:ro}   \
              ${COREOS_ASSEMBLER_GIT:+-v $COREOS_ASSEMBLER_GIT/src/:/usr/lib/coreos-assembler/:ro}  \
              ${COREOS_ASSEMBLER_CONTAINER_RUNTIME_ARGS}                                            \
              ${COREOS_ASSEMBLER_CONTAINER:-quay.io/coreos-assembler/coreos-assembler:latest} "$@"
   rc=$?; set +x; return $rc
}
```

Check out config
```bash
cosa init https://github.com/randomcoww/fedora-silverblue-custom.git --force
```

Run build
```bash
cosa clean && \
cosa fetch && \
cosa build metal4k && \
cosa buildextend-metal && \
cosa buildextend-live
```

This build expects a home directory device with label `localhome` and a swap device with label `swap`

Embed ignition from https://github.com/randomcoww/terraform-infra generated under `outputs/ignition`
```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/resources/output/ignition/client-0.ign \
  -o client-0.iso \
  builds/latest/x86_64/fedora-silverblue-*-live.x86_64.iso

sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/resources/output/ignition/client-1.ign \
  -o client-1.iso \
  builds/latest/x86_64/fedora-silverblue-*-live.x86_64.iso
```
Write client-0.iso to disk

Optionally write directly to disk on running system
```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/resources/output/ignition/client-0.ign \
  /dev/sda --force

sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/resources/output/ignition/client-1.ign \
  /dev/sda --force
```
Reboot to apply changes

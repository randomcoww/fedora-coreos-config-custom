### Prepare

[Define cosa command](../../README.md)

### Check out config

```bash
cosa init --force https://github.com/randomcoww/fedora-coreos-config-custom.git builds/server
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
mc cp -r builds/latest/x86_64/fedora-coreos-*-live-* minio/boot/
```

### Write bootable image to disk

Embed ignition from https://github.com/randomcoww/terraform-infra generated under `outputs/ignition`

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/gw-0.ign \
  -o gw-0.iso \
  builds/latest/x86_64/fedora-coreos-*-live.x86_64.iso
```
```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/gw-1.ign \
  -o gw-1.iso \
  builds/latest/x86_64/fedora-coreos-*-live.x86_64.iso

sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/k-2.ign \
  -o k-2.iso \
  builds/latest/x86_64/fedora-coreos-*-live.x86_64.iso
```

Write to existing device

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/gw-0.ign \
  /dev/sda --force
```
```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/gw-1.ign \
  /dev/sda --force

sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/k-2.ign \
  /dev/sda --force
```

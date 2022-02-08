### Check out config

```bash
cosa init --force https://github.com/randomcoww/fedora-coreos-config-custom.git builds/client
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
mc cp -r builds/latest/x86_64/fedora-silverblue-*-live-* minio/boot/
```

### Write bootable image to disk

Embed ignition from https://github.com/randomcoww/terraform-infra generated under `outputs/ignition`

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/remote-0.ign \
  -o remote-0.iso \
  builds/latest/x86_64/fedora-silverblue-*-live.x86_64.iso
```

Write `remote-0.iso` to disk

Optionally write directly to disk on running system

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/remote-0.ign \
  /dev/sda --force
```
Reboot to apply changes

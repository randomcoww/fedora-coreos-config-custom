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

### Write bootable image to disk


Embed ignition from https://github.com/randomcoww/terraform-infra generated under `outputs/ignition`

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/aio-0.ign \
  -o aio-0.iso \
  builds/latest/x86_64/fedora-coreos-*-live.x86_64.iso
```

Write to existing device

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/aio-0.ign \
  /dev/sda --force
```
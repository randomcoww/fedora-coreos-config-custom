Check out config
```bash
cosa init --force https://github.com/randomcoww/fedora-coreos-config-custom.git builds/laptop
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
```
Write `client-0.iso` to disk

Optionally write directly to disk on running system
```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/resources/output/ignition/client-0.ign \
  /dev/sdb --force
```
Reboot to apply changes

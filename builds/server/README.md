Check out config
```bash
cosa init --force https://github.com/randomcoww/fedora-coreos-config-custom.git builds/server
```

Add matchbox image. This host has no internet access and cannot download containers.
```bash
podman pull quay.io/poseidon/matchbox:latest
podman save --format oci-archive -o matchbox.tar quay.io/poseidon/matchbox:latest
sudo mv matchbox.tar src/config/resources
```

Run build
```bash
cosa clean && \
cosa fetch && \
cosa build metal4k && \
cosa buildextend-metal && \
cosa buildextend-live
```

Embed ignition from https://github.com/randomcoww/terraform-infra generated under `outputs/ignition`
```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/hypervisor-0.ign \
  -o hypervisor-0.iso \
  builds/latest/x86_64/fedora-coreos-*-live.x86_64.iso
```
Write `hypervisor-*.iso` to disk

Write to existing device

```bash
sudo coreos-installer iso ignition embed \
  -i ../terraform-infra/output/ignition/hypervisor-0.ign \
  /dev/sda --force
```
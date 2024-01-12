### Nvidia driver overlay

```bash
KERNEL_VERSION=6.6.10-200.fc39.x86_64
DRIVER_VERSION=545.23.08
TAG=ghcr.io/randomcoww/nvidia-kmod:$KERNEL_VERSION

mkdir -p tmp
TMPDIR=$(pwd)/tmp podman build \
  --build-arg KERNEL_VERSION=$KERNEL_VERSION \
  --build-arg DRIVER_VERSION=$DRIVER_VERSION \
  -f kmod.Containerfile \
  -t $TAG .

podman run --rm \
  -v $(pwd)/../overlay.d/02nvidia/usr/lib:/mnt \
  $TAG cp -r /opt/. /mnt
```

```bash
TAG=ghcr.io/randomcoww/nvidia-patch:latest

mkdir -p tmp
TMPDIR=$(pwd)/tmp podman build \
  -f patch.Containerfile \
  -t $TAG .

mkdir -p usr
podman run --rm \
  -v $(pwd)/usr:/mnt \
  $TAG cp -r /opt/. /mnt
```

## Custom Fedora CoreOS builds

Add and remove components to support:

* Bare metal live ISO and PXE boot only
* systemd-networkd instead of NetworkManager

COSA upstream with full instructions: https://github.com/coreos/coreos-assembler

* CoreOS packages: https://github.com/coreos/fedora-coreos-config.git
* Silverblue packages: https://pagure.io/workstation-ostree-config.git

### Manual build

Enter build image

```bash
mkdir -p builds

podman run -it --rm \
  --entrypoint=bash \
  -e COSA_SUPERMIN_MEMORY=4096 \
  -e VARIANT=coreos \
  -v $(pwd)/builds:/home/builder/builds \
  quay.io/coreos-assembler/coreos-assembler
```

Run build in image

```bash
cd $HOME
sudo dnf install -y --setopt=install_weak_deps=False \
  rpmdevtools \
  dnf-plugins-core \
  git-core \
  libnftnl-devel \
  createrepo

mkdir -p rpmbuild/
cd rpmbuild
git clone -b f$(rpm -E %fedora) https://src.fedoraproject.org/rpms/keepalived.git SOURCES/
cd SOURCES
spectool -gR keepalived.spec
sudo dnf builddep -y keepalived.spec
rpmbuild -bb keepalived.spec \
  --without snmp \
  --with nftables \
  --without debug

find $HOME/rpmbuild/RPMS/ -type d -mindepth 1 -maxdepth 1 -exec createrepo '{}' \;

cd $HOME
cosa init -V $VARIANT \
  --force ${{ github.server_url }}/${{ github.repository }}.git
cosa clean
cosa fetch
cosa build metal4k
cosa buildextend-metal
cosa buildextend-live
```

### Modify kargs example

```bash
coreos-installer iso kargs modify \
  -a systemd.unit=multi-user.target \
  -o output.iso \
  builds/latest/x86_64/fedora-*-live.x86_64.iso
```

### Embed ignition to ISO example

```bash
coreos-installer iso ignition embed \
  -i ignition.ign \
  -o output.iso \
  builds/latest/x86_64/fedora-*-live.x86_64.iso
```
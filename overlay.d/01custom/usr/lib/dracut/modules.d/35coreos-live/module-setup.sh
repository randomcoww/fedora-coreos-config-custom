depends() {
    # We need the rdcore binary
    echo rdcore
}

install_and_enable_unit() {
    unit="$1"; shift
    target="$1"; shift
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "$target" "$unit" || exit 1
}

installkernel() {
    # we do loopmounts
    instmods -c loop
}

install() {
    inst_multiple \
        bsdtar \
        curl \
        truncate

    inst_script "$moddir/is-live-image.sh" \
        "/usr/bin/is-live-image"

    inst_script "$moddir/ostree-cmdline.sh" \
        "/usr/sbin/ostree-cmdline"

    inst_simple "$moddir/live-generator" \
        "$systemdutildir/system-generators/live-generator"

    inst_simple "$moddir/coreos-livepxe-rootfs.sh" \
        "/usr/sbin/coreos-livepxe-rootfs"

    install_and_enable_unit "coreos-livepxe-rootfs.service" \
        "initrd-root-fs.target"
}
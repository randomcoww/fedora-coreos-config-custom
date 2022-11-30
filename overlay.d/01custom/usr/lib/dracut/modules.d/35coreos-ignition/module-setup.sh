#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    echo systemd network ignition coreos-live
}

install_ignition_unit() {
    local unit="$1"; shift
    local target="${1:-ignition-complete.target}"; shift
    local instantiated="${1:-$unit}"; shift
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    # note we `|| exit 1` here so we error out if e.g. the units are missing
    # see https://github.com/coreos/fedora-coreos-config/issues/799
    systemctl -q --root="$initdir" add-requires "$target" "$instantiated" || exit 1
}

install() {
    inst_multiple \
        basename \
        diff \
        lsblk \
        sed \
        grep \
        sgdisk \
        uname

    inst_script "$moddir/coreos-ignition-setup-user.sh" \
        "/usr/sbin/coreos-ignition-setup-user"

    install_ignition_unit coreos-ignition-setup-user.service
}

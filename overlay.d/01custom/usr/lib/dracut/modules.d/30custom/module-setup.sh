install() {
    inst_multiple \
        setfiles

    inst_script "$moddir/coreos-relabel" /usr/bin/coreos-relabel
}
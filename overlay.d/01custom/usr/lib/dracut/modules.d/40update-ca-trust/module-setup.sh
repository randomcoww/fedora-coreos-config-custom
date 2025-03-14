install() {
    inst_multiple \
        update-ca-trust

    install_ignition_unit update-ca-trust.service
}
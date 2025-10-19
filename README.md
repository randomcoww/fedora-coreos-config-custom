## Custom Fedora CoreOS build

Builds Kubernetes and some networking HA tools like Keepalived and HAProxy into upstream COSA base image:

https://github.com/coreos/fedora-coreos-config.git

This repo does not work as is. There is a hack in the build step to copy *.repo files from upstream submodule into the base path. Repo files don't work as symlinks.
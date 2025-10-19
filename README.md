## Custom Fedora CoreOS build

Builds Kubernetes and some networking HA tools like Keepalived and HAProxy into upstream COSA base image:

https://github.com/coreos/fedora-coreos-config.git

This build normally will not work without Fedora and Fedora Upstream repo files in the root path of the project. These files are copied from upstream submodule into the base path during build.
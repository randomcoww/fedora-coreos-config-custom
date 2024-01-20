locals {
  snippets = {
    base = {
      releasever = "39"
      ref        = "fedora/$${releasever}/$${basearch}/coreos"
      include = [
        "manifests/ignition-and-ostree.yaml"
      ]
      ostree-layers = [
        "overlay/01custom"
      ]
      automatic-version-prefix = "$${releasever}.<date:%Y%m%d>"
      mutate-os-release        = "$${releasever}"
      repos = [
        "fedora",
        "fedora-updates",
      ]
      recommends           = false
      readonly-executables = true
      ignore-removed-users = [
        "root",
      ]
      ignore-removed-groups = [
        "root",
      ]
      etc-group-members = [
        "sudo",
        "systemd-journal",
        "adm",
        "wheel",
        "input",
        "video",
      ]
      check-passwd = {
        type     = "file"
        filename = "manifests/passwd"
      }
      check-groups = {
        type     = "file"
        filename = "manifests/group"
      }
      packages = [
        "fedora-repos-ostree",
        "fedora-repos-archive",

        # system-configuration
        "chrony",
        "coreos-installer",
        "coreos-installer-bootinfra",
        "cloud-utils-growpart",
        "cryptsetup",
        "device-mapper-multipath",
        "e2fsprogs",
        "lvm2",
        "mdadm",
        "sg3_utils",
        "xfsprogs",
        "passwd",
        "shadow-utils",
        "acl",
        "selinux-policy-targeted",

        # user-experience
        "bash-completion",
        "coreutils",
        "jq",
        "less",
        "sudo",
        "vim-minimal",
        "bsdtar",
        "bzip2",
        "gzip",
        "tar",
        "xz",
        "zstd",
        "openssh-clients",
        "openssh-server",
        "crun",
        "criu",
        "criu-libs",
        "nvme-cli",

        # fedora-coreos-base
        "iptables-nft",
        "btrfs-progs",
        "sssd-client",
        "attr",
        "openssl",
        "lsof",
        "ncurses",
        "kbd",
        "zram-generator",
        "systemd-resolved",
        "amd-gpu-firmware",
        "intel-gpu-firmware",
        "nvidia-gpu-firmware",

        # networking-tools
        "iproute-tc",
        "nftables",
        "socat",
        "wireless-regdb",
        "iw",

        # custom
        "hostname",
        "systemd-networkd",
        "ssh-key-dir",
        "ldns-utils",
        "pciutils",
        "rsync",
        "strace",
        "kernel",

        # wifi firmware
        "mt7xxx-firmware",
        "iwlegacy-firmware",
        "iwlwifi-dvm-firmware",
        "iwlwifi-mvm-firmware",
        "realtek-firmware",
        "atheros-firmware",
        "brcmfmac-firmware",
      ]

      packages-x86_64 = [
        "irqbalance",
        "thermald",
      ]
      packages-aarch64 = [
        "irqbalance",
      ]
      remove-from-packages = [
        ["dbus-common", "/usr/lib/sysusers.d/dbus.conf"],
        ["podman", "/etc/cni/net.d/.*"],
      ]
      arch-include = {
        x86_64 = [
          "manifests/grub2-removals.yaml",
          "manifests/bootupd.yaml",
        ]
        aarch64 = [
          "manifests/grub2-removals.yaml",
          "manifests/bootupd.yaml",
        ]
      }
    }

    vrrp = {
      repos = [
        "selfhosted",
      ]
      remove-from-packages = [
        ["conntrack-tools", "/etc/conntrackd/conntrackd.conf"],
        ["keepalived", "/etc/keepalived/keepalived.conf"],
        ["haproxy", "/etc/haproxy/haproxy.cfg"],
      ]
      packages = [
        "haproxy",
        "conntrack-tools",
      ]
    }

    kubernetes = {
      repos = [
        "kubernetes",
      ]
      remove-from-packages = [
        ["cri-o", "/etc/cni/net.d/.*"],
        ["conntrack-tools", "/etc/conntrackd/conntrackd.conf"],
      ]
      packages = [
        "containernetworking-plugins",
        "cri-o",
        "cri-tools",
        "kubelet",
        "conntrack-tools",
      ]
    }

    nvidia = {
      ostree-layers = [
        "overlay/02nvidia",
      ]
      repos = [
        "nvidia",
      ]
      remove-from-packages = [
        # ["nvidia-driver-cuda-libs", "/usr/lib64/libnvidia-encode.so.*"],
        # ["nvidia-driver-NvFBCOpenGL", "/usr/lib64/libnvidia-fbc.so.*"],
      ]
      packages = [
        "kmod-nvidia-open-dkms",
        "cuda-drivers",
        "nvidia-drivers",
        "nvidia-container-runtime",
        "nvidia-vaapi-driver",
      ]
    }

    kvm = {
      packages = [
        "libvirt-daemon-kvm",
        "libvirt-client",
        "virt-viewer",
      ]
    }

    laptop = {
      repos = [
        "tailscale-stable",
      ]
      packages = [
        "NetworkManager",
        "NetworkManager-bluetooth",
        "NetworkManager-config-connectivity-fedora",
        "NetworkManager-wifi",
        "tailscale",
      ]
    }

    sunshine = {
      repos = [
        "selfhosted",
      ]
      packages = [
        "sunshine",
      ]
    }

    chromebook = {
      ostree-layers = [
        "overlay/03chromebook"
      ]
      remove-from-packages = [
        ["alsa-ucm", "/usr/share/alsa/ucm2/common/pcm/split.conf"],
        ["alsa-ucm", "/usr/share/alsa/ucm2/codecs/hda/hdmi.conf"],
        ["alsa-sof-firmware", "/usr/lib/firmware/intel/sof-tplg/sof-rpl-rt711.tplg.xz"],
      ]
      packages = [
        "alsa-sof-firmware",
      ]
    }

    desktop-environment = {
      repos = [
        "rpmfusion-free",
        "rpmfusion-free-updates",
        "rpmfusion-nonfree",
        "rpmfusion-nonfree-updates",
        "selfhosted",
        "kubernetes",
      ]
      packages = yamldecode(
        <<EOF
## from fedora-common-ostree.yaml
  - git-core
  - git-core-doc
  - lvm2
  # - rpm-ostree
  # - ostree-grub2
  - buildah
  - podman
  - skopeo
  - toolbox
  - ncurses
  - flatpak
  - xdg-desktop-portal
  # - hfsplus-tools
  # - fedora-repos-ostree
  # - fedora-repos-archive

## from fedora-common-ostree-pkgs.yaml
  # - NetworkManager
  # - NetworkManager-bluetooth
  # - NetworkManager-config-connectivity-fedora
  # - NetworkManager-wifi
  # - NetworkManager-wwan
  - acl
  - alsa-ucm
  - alsa-utils
  - amd-gpu-firmware
  - atheros-firmware
  - attr
  # - audit
  - b43-fwcutter
  - b43-openfwwf
  - basesystem
  - bash
  - bash-color-prompt
  - bash-completion
  - bc
  # - bind-utils
  - bluez-cups
  - brcmfmac-firmware
  - btrfs-progs
  - bzip2
  # - chrony
  # - cifs-utils
  - colord
  - compsize
  - coreutils
  - cpio
  - cryptsetup
  - cups
  - cups-browsed
  - cups-filters
  - curl
  # - cyrus-sasl-plain
  # - default-editor
  - default-fonts-cjk-mono
  - default-fonts-cjk-sans
  - default-fonts-cjk-serif
  - default-fonts-core-emoji
  - default-fonts-core-math
  - default-fonts-core-mono
  - default-fonts-core-sans
  - default-fonts-core-serif
  - default-fonts-other-mono
  - default-fonts-other-sans
  - default-fonts-other-serif
  # - dhcp-client
  # - dnsmasq
  - e2fsprogs
  - ethtool
  - exfatprogs
  # - fedora-bookmarks
  # - fedora-chromium-config
  - fedora-flathub-remote
  # - fedora-workstation-backgrounds
  # - fedora-workstation-repositories
  - file
  - filesystem
  # - firefox
  # - firewalld
  # - fpaste
  # - fros-gnome
  - fwupd
  - gamemode
  - glibc
  - glibc-all-langpacks
  - gnupg2
  - gstreamer1-plugin-libav
  - gstreamer1-plugins-bad-free
  - gstreamer1-plugins-good
  - gstreamer1-plugins-ugly-free
  - gutenprint
  - gutenprint-cups
  - hostname
  - hplip
  - hunspell
  - ibus-anthy
  - ibus-gtk3
  - ibus-gtk4
  - ibus-hangul
  - ibus-libpinyin
  - ibus-libzhuyin
  - ibus-m17n
  - ibus-typing-booster
  - intel-gpu-firmware
  # - iproute
  - iptables-nft
  - iptstate
  - iputils
  - iwlegacy-firmware
  - iwlwifi-dvm-firmware
  - iwlwifi-mvm-firmware
  - kbd
  - kernel
  - kernel-modules-extra
  - less
  - libertas-firmware
  # - libglvnd-gles
  - linux-firmware
  # - logrotate
  - lrzsz
  - lsof
  - man-db
  - man-pages
  - mdadm
  - mpage
  - mt7xxx-firmware
  - mtr
  # - nfs-utils
  - nss-altfiles
  - nss-mdns
  # - ntfs-3g
  # - ntfsprogs
  - nvidia-gpu-firmware
  - opensc
  - openssh-clients
  - openssh-server
  - pam_afs_session
  - paps
  - passwd
  - passwdqc
  - pciutils
  - pinfo
  - pipewire-alsa
  - pipewire-gstreamer
  - pipewire-pulseaudio
  - pipewire-utils
  - plocate
  # - plymouth
  # - plymouth-system-theme
  - policycoreutils
  # - policycoreutils-python-utils
  - procps-ng
  - psmisc
  - qemu-guest-agent
  # - qt5-qtbase
  # - qt5-qtbase-gui
  # - qt5-qtdeclarative
  # - qt5-qtxmlpatterns
  - quota
  - realmd
  - realtek-firmware
  - rootfiles
  - rpm
  - rsync
  # - samba-client
  - selinux-policy-targeted
  - setup
  - shadow-utils
  # - sos
  # - spice-vdagent
  # - spice-webdavd
  # - sssd
  # - sssd-common
  # - sssd-kcm
  - sudo
  - system-config-printer-udev
  - systemd
  - systemd-oomd-defaults
  - systemd-resolved
  - systemd-udev
  - tar
  - time
  - toolbox
  - tree
  - unzip
  - uresourced
  - usb_modeswitch
  - usbutils
  - util-linux
  - vim-minimal
  - wget
  - which
  - whois
  - wireplumber
  - words
  - wpa_supplicant
  - zip
  - zram-generator-defaults

## from gnome-desktop-pkgs.yaml
  # - ModemManager
  # - NetworkManager-adsl
  # - NetworkManager-openconnect-gnome
  # - NetworkManager-openvpn-gnome
  # - NetworkManager-ppp
  # - NetworkManager-pptp-gnome
  # - NetworkManager-ssh-gnome
  # - NetworkManager-vpnc-gnome
  # - NetworkManager-wwan
  - adobe-source-code-pro-fonts
  - at-spi2-atk
  - at-spi2-core
  - avahi
  - dconf
  - fprintd-pam
  - gdm
  - glib-networking
  - glx-utils
  # - gnome-backgrounds
  - gnome-bluetooth
  # - gnome-browser-connector
  # - gnome-classic-session
  - gnome-color-manager
  - gnome-control-center
  # - gnome-disk-utility
  # - gnome-initial-setup
  # - gnome-remote-desktop
  - gnome-session-wayland-session
  # - gnome-session-xsession
  - gnome-settings-daemon
  - gnome-shell
  # - gnome-software
  # - gnome-system-monitor
  - gnome-terminal
  - gnome-terminal-nautilus
  # - gnome-user-docs
  # - gnome-user-share
  - gvfs-afc
  # - gvfs-afp
  - gvfs-archive
  - gvfs-fuse
  - gvfs-goa
  - gvfs-gphoto2
  - gvfs-mtp
  # - gvfs-smb
  - librsvg2
  - libsane-hpaio
  - mesa-dri-drivers
  - mesa-libEGL
  - mesa-vulkan-drivers
  - nautilus
  # - orca
  - polkit
  # - rygel
  - systemd-oomd-defaults
  - tracker
  - tracker-miners
  - xdg-desktop-portal
  - xdg-desktop-portal-gnome
  - xdg-desktop-portal-wlr
  - xdg-user-dirs-gtk
  # - yelp

## custom
  - intel-media-driver
  - mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld
  - slirp4netns podman-plugins netavark aardvark-dns
  - libva-utils
  - vulkan vulkan-tools
  - tmux xclip
  - kubectl helm
  - nmap

## peripheral support
  - opentabletdriver
  - dymo-cups-drivers
  # https://www.reddit.com/r/Fedora/comments/ocn6ko/usb_tethering_with_ios_146_on_fedora/
  - libimobiledevice-utils usbmuxd
  EOF
      )
    }

    release-coreos = {
      documentation = false
      rojig = {
        license = "MIT"
        name    = "fedora-coreos"
        summary = "Fedora CoreOS"
      }
      default-target = "multi-user.target"
      remove-files = [
        "usr/share/info",
        "usr/share/man",
        "usr/share/doc",
      ]
      packages = [
        "fedora-release-coreos",
      ]
    }

    release-silverblue = {
      rojig = {
        license = "MIT"
        name    = "fedora-silverblue"
        summary = "Fedora Silverblue"
      }
      default-target = "graphical.target"
      packages = [
        "fedora-release-silverblue",
      ]
    }

    image-base = {
      extra-kargs = [
        "iommu=pt",
        "amd_iommu=pt",
        "rd.driver.pre=vfio-pci",
        "numa=off",
        "enforcing=0",
      ]
      ignition-network-kcmdline = []
      ostree-remote             = "fedora"
      compressor                = "xz"
    }

    image-coreos = {
      size = 1
    }

    image-nvidia = {
      size = 4
      extra-kargs = [
        "rd.driver.blacklist=nouveau",
        "modprobe.blacklist=nouveau",
        "nvidia_drm.modeset=1",
      ]
    }

    image-chromebook = {
      size = 4
      extra-kargs = [
        "pci=nommconf",
        "snd-intel-dspcfg.dsp_driver=3",
      ]
    }
  }
}

## variables, output

variable "manifests" {
  type    = list(string)
  default = []
}

variable "exclude_packages" {
  type    = list(string)
  default = []
}

variable "image" {
  type    = string
  default = "image-coreos"
}

variable "image_base" {
  type    = string
  default = "image-base"
}

resource "local_file" "manifests" {
  for_each = merge({
    for k in concat(var.manifests, [var.image_base]) :
    k => local.snippets[k]
    }, {
    "manifest" = {
      include = [
        for k in var.manifests :
        "${k}.yaml"
      ]
      exclude-packages = var.exclude_packages
    }
  })
  filename = "${path.module}/../${each.key}.yaml"
  content  = yamlencode(each.value)
}

resource "local_file" "image" {
  filename = "${path.module}/../image.yaml"
  content = yamlencode(merge(local.snippets[var.image], {
    include = "${var.image_base}.yaml"
  }))
}
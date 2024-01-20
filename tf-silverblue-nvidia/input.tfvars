manifests = [
  "base",
  "vrrp",
  "kubernetes",
  "nvidia",
  "kvm",
  "desktop-environment",
  "release-silverblue",
]
exclude_packages = [
  "python",
  "python2",
  "python2-libs",
  "perl",
  "nodejs",
  "dnf",
  "cowsay",
  "initscripts",
  "plymouth",
  "NetworkManager",
  "NetworkManager-initscripts-ifcfg-rh",
  "PackageKit",
]
image_base = "image-base"
image = "image-nvidia"
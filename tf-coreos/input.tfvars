manifests = [
  "base",
  "vrrp",
  "kubernetes",
  "release-coreos",
]
exclude_packages = [
  "python",
  "python2",
  "python2-libs",
  "python3",
  "python3-libs",
  "perl",
  "perl-interpreter",
  "nodejs",
  "dnf",
  "grubby",
  "cowsay",
  "initscripts",
  "plymouth",
  "NetworkManager",
  "NetworkManager-libnm",
  "NetworkManager-initscripts-ifcfg-rh",
  "PackageKit",
]
image_base = "image-base"
image = "image-coreos"
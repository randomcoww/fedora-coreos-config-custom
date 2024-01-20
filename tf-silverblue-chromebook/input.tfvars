manifests = [
  "base",
  "kubernetes",
  "laptop",
  "chromebook",
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
  "NetworkManager-initscripts-ifcfg-rh",
  "PackageKit",
]
image_base = "image-base"
image = "image-chromebook"
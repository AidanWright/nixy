# modules/programs/_streaming-services.nix
################################################################################
# Streaming hostnames that need DRM Safari plays but LibreWolf refuses. Shared
# by finicky.nix (routes these to Safari) and librewolf-safari-redirect.nix (the
# in-browser catch), so the two stay in sync. Underscore-prefixed: import-tree
# skips it, so it is plain data imported directly rather than a flake module.
################################################################################
[
  "netflix.com"
  "max.com"
  "hbomax.com"
  "disneyplus.com"
  "primevideo.com"
  "hulu.com"
  "peacocktv.com"
  "paramountplus.com"
  "crunchyroll.com"
  "tv.apple.com"
]

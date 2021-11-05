{ pkgs
, config
, dev-commons ? import ./dev-commons.nix { inherit pkgs config; }
, extraToolchainComponents
}:

with dev-commons.commons;
dev-commons.createToolchain {
  inherit extraToolchainComponents;

  target = targets.musl;
  toolchain = stable;
}

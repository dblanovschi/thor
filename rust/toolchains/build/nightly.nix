{ pkgs
, config
, build-commons ? import ./build-commons.nix { inherit pkgs config; }
, extraToolchainComponents
}:

with build-commons.commons;
build-commons.createToolchain {
  inherit extraToolchainComponents;

  target = targets.gnu;
  toolchain = nightly;
}

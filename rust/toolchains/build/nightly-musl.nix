{ pkgs, config, build-commons ? import ./build-commons.nix { inherit pkgs config; } }:

with build-commons.commons;
build-commons.createToolchain {
  target = targets.musl;
  toolchain = nightly;
}

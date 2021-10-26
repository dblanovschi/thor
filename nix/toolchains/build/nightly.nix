{ pkgs, build-commons ? import ./build-commons.nix { inherit pkgs; } }:

with build-commons.commons;
build-commons.createToolchain {
  target = targets.gnu;
  toolchain = nightly;
}

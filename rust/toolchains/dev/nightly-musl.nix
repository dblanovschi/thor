{ pkgs, config, dev-commons ? import ./dev-commons.nix { inherit pkgs config; } }:

with dev-commons.commons;
dev-commons.createToolchain {
  target = targets.musl;
  toolchain = nightly;
}

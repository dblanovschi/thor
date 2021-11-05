{ pkgs, config, commons ? import ../commons.nix { inherit pkgs config; }, lib ? pkgs.lib }:

{
  inherit commons;
  createToolchain = commons.createToolchain {
    profile = (toolchain: toolchain.minimal);
  };
}

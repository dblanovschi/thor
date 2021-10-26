{ pkgs, commons ? import ../commons.nix { inherit pkgs; }, lib ? pkgs.lib }:

{
  inherit commons;
  createToolchain = commons.createToolchain {
    profile = (toolchain: toolchain.minimal);
  };
}

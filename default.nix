{ pkgs ? import <nixpkgs> { overlays = (import ./nix/overlays.nix); } }:

{
  inherit pkgs;

  mkShell = import ./nix/shell.nix { inherit pkgs; };
  toolchainCommons = import ./nix/toolchains/commons.nix { inherit pkgs; };
  toolchain =
    { toolchain, action ? "dev" }:
    import ./nix/toolchain.nix { inherit pkgs toolchain action; };
}

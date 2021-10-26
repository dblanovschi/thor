{ extra-overlays ? [ ]
  # Want to pass your own pkgs? Then add the rust-overlay, like so:
  # import <nixpkgs> { overlays = [(import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))]; }
  # and then pass it.
, pkgs ? import <nixpkgs> { overlays = (import ./nix/overlays.nix) ++ extra-overlays; }
}:

{
  inherit pkgs;

  mkRustShell = import ./nix/shell.nix { inherit pkgs; };
  toolchainCommons = import ./nix/toolchains/commons.nix { inherit pkgs; };
  toolchain =
    { toolchain, action ? "dev" }:
    import ./nix/toolchain.nix { inherit pkgs toolchain action; };
}

{ pkgs ? import <nixpkgs> { overlays = [(import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))]; } }:

{
  inherit pkgs;

  mkShell = (import ./nix/shell.nix) pkgs;
}

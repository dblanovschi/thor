{ extraOverlays ? [ ]
, pkgs ? import <nixpkgs> { overlays = (import ./rust/overlays.nix) ++ extraOverlays; }
, lib ? pkgs.lib
, config ? { }
}:

let
  cfg = import ./config/default.nix { inherit lib; };
  c' = cfg.buildAndCheck { inherit config pkgs; };

  # Rust stuff
  rust =
    if c'.rust.enable then {
      rust = {
        toolchainCommons = import ./rust/toolchains/commons.nix { inherit pkgs; config = c'; };

        toolchain =
          { toolchain, action ? "dev" }:
          import ./rust/toolchain.nix { inherit pkgs toolchain action; config = c'; };

        inherit (import ./rust/shell.nix { inherit pkgs; config = c'; }) mkRustShell rustShell;
      };
    } else { };

  # Nix stuff
  nix = {
    shell = {
      inherit (import ./nix/shell.nix { inherit pkgs; config = c'; }) mergeShells mkMergedShell;
    };
  };
in
{ inherit pkgs; } // rust // nix

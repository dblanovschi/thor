{ lib }:

let
  rust' = import ./rust.nix;
in
rec {
  default = {
    rust = rust'.default;
  };

  build = lib.recursiveUpdate default;

  check = self: pkgs: self
    // { rust = rust'.check self.rust pkgs; } # check rust
  ;

  buildAndCheck = { config, pkgs }: check (build config) pkgs;
}

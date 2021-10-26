{ pkgs, toolchain, action ? "dev" }:


let
  valid-toolchains = [
    "nightly-musl"
    "nightly"
    "stable-musl"
    "stable"
  ];

  valid-actions = [
    "dev"
    "build"
  ];

  valid-toolchain = t: (builtins.any (tch: t == tch) valid-toolchains);
  valid-action = act: (builtins.any (a: act == a) valid-actions);

  path-for =
    toolchain:
    action:
    if valid-toolchain toolchain
    then if valid-action action then ./. + "/toolchains/${action}/${toolchain}.nix"
    else abort "ERROR: rust-setup: unknown action ${builtins.toJSON action}, valid values are ${builtins.toJSON valid-actions}"
    else abort "ERROR: rust-setup: unknown toolchain ${builtins.toJSON toolchain}, valid values are ${builtins.toJSON valid-toolchains}";

in

import (path-for toolchain action) { inherit pkgs; }

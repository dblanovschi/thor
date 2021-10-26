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

  valid-toolchain-name = tch: (builtins.any (t: tch == t) valid-toolchains);
  valid-toolchain-struct =
    tch: builtins.hasAttr "toolchain" tch
      && builtins.hasAttr "target" tch;

  valid-action = act: (builtins.any (a: act == a) valid-actions);

  action-commons-path = act: (./. + "/toolchains/${act}/${act}-commons.nix");

  getToolchain =
    toolchain:
    action:
    if valid-action action
    then
      (
        if valid-toolchain-name toolchain then import (./. + "/toolchains/${action}/${toolchain}.nix") { inherit pkgs; }
        else
          (
            if valid-toolchain-struct toolchain
            then ((import (action-commons-path action) {inherit pkgs;}).createToolchain) (builtins.trace toolchain toolchain)
            else abort "ERROR: unknown toolchain ${builtins.toJSON toolchain}, valid values are ${builtins.toJSON valid-toolchains} and {target=...; toolchain=...;}"
          )
      )
    else abort "ERROR: unknown action ${builtins.toJSON action}, valid values are ${builtins.toJSON valid-actions}";

in
getToolchain toolchain action

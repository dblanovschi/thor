{ pkgs, toolchain, config, action, extraToolchainComponents }:


let
  validToolchains = [
    "nightly-musl"
    "nightly"
    "stable-musl"
    "stable"
  ];

  validActions = [
    "dev"
    "build"
  ];

  validToolchainName = tch: (builtins.any (t: tch == t) validToolchains);
  validToolchainStruct = tch: tch ? toolchain &&
    (tch ? target || (tch ? targets && tch ? defaultTarget));

  validAction = act: (builtins.any (a: act == a) validActions);

  actionCommonsPath = act: (./. + "/toolchains/${act}/${act}-commons.nix");

  getToolchain =
    toolchain:
    action:
    if validAction action
    then
      (
        if validToolchainName toolchain
        then import (./. + "/toolchains/${action}/${toolchain}.nix") { inherit pkgs config extraToolchainComponents; }
        else
          (
            if validToolchainStruct toolchain
            then ((import (actionCommonsPath action) { inherit pkgs config; }).createToolchain) toolchain
            else abort "ERROR: unknown toolchain ${builtins.toJSON toolchain}, valid values are ${builtins.toJSON validToolchains}, {target=...; toolchain=...; extraToolchainComponents=...;}, and {targets=...; defaultTarget=...; toolchain=...; extraToolchainComponents=...;}"
          )
      )
    else abort "ERROR: unknown action ${builtins.toJSON action}, valid values are ${builtins.toJSON validActions}";

in
getToolchain toolchain action

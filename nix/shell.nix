{ pkgs
, lib ? pkgs.lib
, toolchain-name ? "nightly-musl"
, extraNativeBuildInputs ? [ ]
, extraBuildInputs ? [ ]
, preCargoSetup ? ""
, postCargoSetup ? ""
, setupCargoEnv ? true
, uselld ? true
, enableNightlyOpts ? true
}:

let
  toolchain = (import ./toolchain.nix {
    inherit pkgs;
    toolchain = toolchain-name;
    action = "dev";
  });
  env-commons = (import ./env-commons.nix {
    inherit lib uselld enableNightlyOpts;
    target = toolchain.target;
    isNightly = toolchain.isNightly;
  });
  cargoEnvSetupSh = if setupCargoEnv then env-commons.setup else "";
in
pkgs.mkShell {
  nativeBuildInputs = [
    toolchain.toolchain
  ] ++ extraNativeBuildInputs
  ++ lib.optionals uselld [
    pkgs.clang_12
    pkgs.lld_12
  ];

  buildInputs = [
    pkgs.nixpkgs-fmt
  ] ++ extraBuildInputs;

  shellHook = preCargoSetup + cargoEnvSetupSh + postCargoSetup;
}

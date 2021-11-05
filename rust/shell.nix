{ pkgs, config }:

rec {
  mkRustShell = setup: pkgs.mkShell (rustShell setup);

  rustShell =
    { lib ? pkgs.lib
    , toolchain ? config.rust.defaultToolchain
    , extraNativeBuildInputs ? [ ]
    , extraBuildInputs ? [ ]
    , preCargoSetup ? ""
    , postCargoSetup ? ""
    , setupCargoEnv ? true
    , uselld ? true
    , enableNightlyOpts ? true
    , cargoAliases ? {}
    , enableIncremental ? false
    }:

    let
      toolchain' = (import ./toolchain.nix {
        inherit pkgs toolchain config;
        action = "dev";
      });
      envCommons = (import ./env-commons.nix {
        inherit uselld enableNightlyOpts cargoAliases enableIncremental lib config;
        target = toolchain'.target;
        isNightly = toolchain'.isNightly;
      });
      cargoEnvSetupSh = if setupCargoEnv then envCommons.setup else "";
    in
    {
      nativeBuildInputs = [
        toolchain'.toolchain
      ] ++ extraNativeBuildInputs
      ++ lib.optionals uselld [
        pkgs.clang_12
        pkgs.lld_12
      ];

      buildInputs = [ ] ++ extraBuildInputs;

      shellHook = preCargoSetup + cargoEnvSetupSh + postCargoSetup;
    };
}

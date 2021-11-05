{ target
, isNightly
, enableNightlyOpts
, uselld
, cargoAliases
, enableIncremental
, lib
, config
}:

let
  t = target.targetTriple;

  targetTripleForEnv = s: lib.toUpper (lib.replaceChars [ "-" ] [ "_" ] s);
  TT = targetTripleForEnv t;

  useNightlyOpts = isNightly && enableNightlyOpts;

  linkerRustFlags = lld: lib.optionals lld [ "-Clink-arg=-fuse-ld=lld" ];

  nightlyRustFlags = nightlyOpts: lib.optionals nightlyOpts [ "-Zshare-generics=y" ];

  rustFlags = { lld, nightlyOpts }: linkerRustFlags lld ++ nightlyRustFlags nightlyOpts;
  rustFlagsStr = { lld, nightlyOpts }: builtins.concatStringsSep " " (rustFlags { inherit lld nightlyOpts; });

  cargoAliasesEnvAttrset = lib.mapAttrs' (name: value: lib.nameValuePair "CARGO_ALIAS_${lib.toUpper name}" value);

  cargoSetupEnvAttrset = { CARGO_BUILD_TARGET = "${t}"; }
    // lib.optionalAttrs uselld {
    "CARGO_TARGET_${TT}_LINKER" = "clang";
  }
    // {
    "CARGO_TARGET_${TT}_RUSTFLAGS" = "${
        rustFlagsStr {
          lld = uselld;
          nightlyOpts = useNightlyOpts;
        }
      }";
  }
    // cargoAliasesEnvAttrset cargoAliases
    // (if enableIncremental then {
    CARGO_INCREMENTAL = "1";
    # RUSTC_FORCE_INCREMENTAL = "1";
  } else {
    CARGO_INCREMENTAL = "0";
    # RUSTC_FORCE_INCREMENTAL = "0";
  });
in
{
  setup = cargoSetupEnvAttrset;
}

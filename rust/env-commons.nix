{ targets
, defaultTarget
, isNightly
, enableNightlyOpts
, uselld
, cargoAliases
, enableIncremental
, lib
, config
}:

let
  targetTripleForEnv = s: lib.toUpper (lib.replaceChars [ "-" ] [ "_" ] s);
  TT = t: targetTripleForEnv (t.targetTriple);

  useNightlyOpts = isNightly && enableNightlyOpts;

  linkerRustFlags = lld: lib.optionals lld [ "-Clink-arg=-fuse-ld=lld" ];

  nightlyRustFlags = nightlyOpts: lib.optionals nightlyOpts [ "-Zshare-generics=y" ];

  rustFlags = { lld, nightlyOpts }: linkerRustFlags lld ++ nightlyRustFlags nightlyOpts;
  rustFlagsStr = { lld, nightlyOpts }: builtins.concatStringsSep " " (rustFlags { inherit lld nightlyOpts; });

  cargoAliasesEnvAttrset = lib.mapAttrs' (name: value: lib.nameValuePair "CARGO_ALIAS_${lib.toUpper name}" value);

  targetOpts = t: lib.optionalAttrs uselld
    {
      "CARGO_TARGET_${TT t}_LINKER" = "clang";
    }
  // {
    "CARGO_TARGET_${TT t}_RUSTFLAGS" = "${
        rustFlagsStr {
          lld = uselld;
          nightlyOpts = useNightlyOpts;
        }
      }";
  };

  baseEnvAttrSet = { CARGO_BUILD_TARGET = "${defaultTarget.targetTriple}"; }
    // cargoAliasesEnvAttrset cargoAliases
    // (if enableIncremental then {
    CARGO_INCREMENTAL = "1";
    # RUSTC_FORCE_INCREMENTAL = "1";
  } else {
    CARGO_INCREMENTAL = "0";
    # RUSTC_FORCE_INCREMENTAL = "0";
  });

  cargoSetupEnvAttrset = lib.foldl' (a: b: a//b) baseEnvAttrSet (builtins.map targetOpts targets);
in
{
  setup = cargoSetupEnvAttrset;
}

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

  cargoAliasesList = lib.mapAttrsToList (name: value: ''export CARGO_ALIAS_${lib.toUpper name}="${value}"'');

  cargoSetupList = [
    ''export CARGO_BUILD_TARGET="${t}"''
  ]
  ++ lib.optionals uselld [
    ''export CARGO_TARGET_${TT}_LINKER="clang"''
  ]
  ++ [
    ''export CARGO_TARGET_${TT}_RUSTFLAGS="${
        rustFlagsStr {
          lld = uselld;
          nightlyOpts = useNightlyOpts;
        }
      }"''
  ]
  ++ cargoAliasesList cargoAliases
  ++ (if enableIncremental then [
    ''export CARGO_INCREMENTAL=1''
    ''export RUSTC_FORCE_INCREMENTAL=1''
  ] else [
    ''export CARGO_INCREMENTAL=0''
  ]);
in
{
  setup = builtins.concatStringsSep "\n" cargoSetupList;
}

{ target
, isNightly
, enableNightlyOpts
, uselld
, lib
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
  ];
in
{
  setup = builtins.concatStringsSep "\n" cargoSetupList;
}

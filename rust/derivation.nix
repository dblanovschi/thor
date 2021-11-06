{ pkgs, stdenv ? pkgs.stdenv, config }:

let
  isBuild = phases: phases.build or true;
in
rec {
  mkRustDerivation = setup: stdenv.mkDerivation (rustDerivation setup);

  rustDerivation =
    { pname ? ""
    , version ? ""
    , name ? "${pname}-${version}"
    , src ? null
    , srcs ? null
    , cargoLock ? null
    , cargoLockContents ? null
    , lib ? pkgs.lib
    , toolchain ? config.rust.defaultToolchain
    , extraToolchainComponents ? [ ]
    , nativeBuildInputs ? [ ]
    , buildInputs ? [ ]
    , cargoSetupOverride ? { }
    , setupCargoEnv ? true
    , uselld ? true
    , enableNightlyOpts ? true
    , cargoAliases ? { }
    , shellKind ? config.shell
    , shellAliases ? buildShellAliases
    , buildShellAliases ? { }
    , enableIncremental ? false
    , action ? "dev"
    , phases ? { }
    , hasVendor ? false
    , hasVendorConfig ? false
    }:
      assert isBuild phases && ((src == null) != (srcs == null));
      assert isBuild phases && ((cargoLock == null) != (cargoLockContents == null));

      let
        zdotdir = import
          (builtins.fetchurl {
            url = "https://gist.githubusercontent.com/chisui/bba90fccc930f614743dc259fbadae6d/raw/4108222addc1d646c1b0a6d12130083e2219ad28/zdotdir.nix";
          })
          { inherit pkgs; };

        toolchain' = (import ./toolchain.nix {
          inherit pkgs toolchain config action extraToolchainComponents;
        });
        envCommons = (import ./env-commons.nix {
          inherit uselld enableNightlyOpts cargoAliases enableIncremental lib config;
          inherit (toolchain') targets defaultTarget;
          isNightly = toolchain'.isNightly;
        });
        cargoEnvSetup = lib.optionalAttrs setupCargoEnv envCommons.setup
          // cargoSetupOverride;

        shellAliasValueAttrset =
          { alias
          , isCargoTest ? false
          , testTarget ? config.rust.defaultTestTarget
          }:
          if isCargoTest
          then ''CARGO_BUILD_TARGET="${testTarget}" ${alias}''
          else alias;

        shellAliasValue = value: (
          if builtins.isString value then value
          else if builtins.isAttrs value then shellAliasValueAttrset value
          else abort ("Invalid value for shell alias: ${builtins.toJSON value}")
        );

        shellAliasesList = lib.mapAttrsToList (name: value: ''alias ${name}="${shellAliasValue value}"'');
        shellAliasesStr = aliases: builtins.concatStringsSep "\n" (shellAliasesList aliases);

        extraNativeBuildInputs = nativeBuildInputs;
        extraBuildInputs = buildInputs;

        shellSetup = { shellKind }:
          (if shellKind == "zsh"
          then
            zdotdir
              {
                zshrc = (shellAliasesStr shellAliases) + "\n";
              }
          else if shellKind == "bash"
          then ''
            ${shellAliasesStr shellAliases}
          ''
          else abort (''Invalid value for ${shellKind}: valid values are "bash" and "zsh"'')
          );

        shellKind' = if action == "build" then "bash" else shellKind;

        cargoLockFileContents = if cargoLock != null then builtins.readFile cargoLock else cargoLockContents;

        cgLock = (builtins.fromTOML cargoLockFileContents);
        packages = cgLock.package;

        fetchPkg = pkg: builtins.fetchurl {
          name = "crates-io-${pkg.name}-${pkg.version}.tar.gz";
          url = "https://crates.io/api/v1/crates/${pkg.name}/${pkg.version}/download";
          # url = "https://static.crates.io/crates/${pkg.name}/${pkg.name}-${pkg.version}.crate";
          # sha256 = pkg.checksum;
        };

        fetchUnpackPkg = pkg:
          let
            crateTarball = fetchPkg pkg;
          in
          pkgs.runCommand "${pkg.name}-${pkg.version}" { } ''
            mkdir "$out"
            tar xf "${crateTarball}" -C "$out" --strip-components=1
            # Cargo is happy with largely empty metadata.
            printf '{"files":{},"package":"${pkg.checksum}"}' > "$out/.cargo-checksum.json"
          '';

        fetchPkgs = pkgs: builtins.map
          (pkg: { inherit pkg; path = fetchUnpackPkg pkg; })
          (builtins.filter (pkg: pkg ? checksum) pkgs);
        linkPkgs = pkgs: builtins.map
          (p: ''
            if [ ! -d "$out/vendor/${p.pkg.name}" ]
            then ln "${p.path}" -s "$out/vendor/${p.pkg.name}"
            else ln "${p.path}" -s "$out/vendor/${p.pkg.name}-${p.pkg.version}"
            fi
          '')
          (fetchPkgs pkgs);
        linkPkgsString = pkgs: builtins.concatStringsSep "\n" (linkPkgs pkgs);

        n' = name;
        vendorDer = pkgs: stdenv.mkDerivation {
          name = "${n'}_vendor_deriv";
          nativeBuildInputs = [ toolchain'.toolchain ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p "$out/vendor"
            ${linkPkgsString packages}
          '';
        };

        implPhases =
          s@{ build ? true
          , phases ? [
              # "prePhases" # $
              "unpackPhase"
              "patchPhase"
              # "preConfigurePhases" # $
              "configurePhase"
              # "preBuildPhases" # $
              "buildPhase"
              "checkPhase"
              # "preInstallPhases" # $
              "installPhase"
              "fixupPhase"
              "installCheckPhase"
              # "preDistPhases" # $
              "distPhase"
              # "postPhases" # $
            ]
          , ...
          }:
          if ! build then {
            phases = [ "noBuild" ];
            noBuild = ''
              echo
              echo "Not meant to be built, aborting"
              echo
              exit 1
            '';
          } else
            let p' = [ "thor_setupVendor" ] ++ phases; in
            {
              phases = p';
            } // lib.mapAttrs
              (name: value:
              if value != "" then
                (
                  ''
                    ${shellAliasesStr buildShellAliases}

                    ${value}
                  ''
                ) else "")
              (lib.fold (a: b: a // b) { } (builtins.map
                (phase: {
                  ${phase} = s.${phase} or "";
                })
                phases))
            // (
              let setupVendorConfig =
                if hasVendorConfig
                then ""
                else ''
                  mkdir -p .cargo
                  cat >> .cargo/config <<EOF
                  [source.crates-io]
                  replace-with = "vendored-sources"

                  [source.vendored-sources]
                  directory = "vendor"
                  EOF
                '';
              in
              if hasVendor then {
                thor_setupVendor = setupVendorConfig;
              } else {
                thor_setupVendor = ''
                  ln -s ${vendorDer packages}/vendor ./vendor

                  ${setupVendorConfig}
                '';
              }
            );
      in
      (implPhases phases) //
      {
        inherit name pname version src srcs;

        nativeBuildInputs = [
          toolchain'.toolchain
        ] ++ extraNativeBuildInputs
        ++ lib.optionals uselld [
          pkgs.clang_12
          pkgs.lld_12
        ];

        buildInputs = extraBuildInputs;

        shellHook = shellSetup { shellKind = shellKind'; };
      } // cargoEnvSetup;
}

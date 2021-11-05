{ pkgs, lib ? pkgs.lib, config }:

let
  st = pkgs.rust-bin.stable;
  stl = st.latest;

  bt = pkgs.rust-bin.beta;
  btl = bt.latest;

  nt = pkgs.rust-bin.nightly;
  ntl = nt.latest;

  missingValue = ".";

  ttt = { arch, type, os, lib }:
    arch +
    (if type != missingValue then "-${type}" else "") +
    "-${os}" +
    (if lib != missingValue then "-${lib}" else "");

  createTargetTriple = { arch, type ? missingValue, os, lib ? missingValue }: {
    inherit arch type os lib;

    targetTriple = ttt { inherit arch type os lib; };
  };

  applyOverrideTargetMap = ov: ov // { targets = (map (it: it.targetTriple) ov.targets); };
  utilOverride = toolchain: profile: override: (profile toolchain).override (applyOverrideTargetMap override);
in
rec {
  targets = rec {
    x86_64-windows-msvc = createTargetTriple { arch = "x86_64"; type = "pc"; os = "windows"; lib = "msvc"; };
    x86_64-windows-gnu = createTargetTriple { arch = "x86_64"; type = "pc"; os = "windows"; lib = "gnu"; };

    x86_64-linux-musl = createTargetTriple { arch = "x86_64"; type = "unknown"; os = "linux"; lib = "musl"; };
    x86_64-linux-gnu = createTargetTriple { arch = "x86_64"; type = "unknown"; os = "linux"; lib = "gnu"; };

    i686-windows-msvc = createTargetTriple { arch = "i686"; type = "pc"; os = "windows"; lib = "msvc"; };
    i686-windows-gnu = createTargetTriple { arch = "i686"; type = "pc"; os = "windows"; lib = "gnu"; };

    # Aliases
    x86_64-windows-mingw = x86_64-windows-gnu;
    i686-windows-mingw = i686-windows-gnu;

    win-msvc = x86_64-windows-msvc;
    win-gnu = x86_64-windows-gnu;
    win-mingw = win-gnu;

    musl = x86_64-linux-musl;
    gnu = x86_64-linux-gnu;

    default = gnu;
  };

  minimal = toolchain: toolchain.minimal;
  default = toolchain: toolchain.default;

  nightly = {
    t = profile:
      override:
      (pkgs.rust-bin.selectLatestNightlyWith (toolchain: (utilOverride toolchain profile override)));
    isNightly = true;
  };

  beta = { t = utilOverride btl; isNightly = false; };
  stable = { t = utilOverride stl; isNightly = false; };

  from-toolchain = pkgs.rust-bin.fromRustupToolchainFile;

  createToolchain =
    { profile, baseExtensions ? [ ] }:
    { target, toolchain, extraToolchainComponents ? [ ] }: {
      inherit target;

      toolchain = (toolchain.t) profile {
        extensions = lib.unique (baseExtensions ++ extraToolchainComponents);
        targets = [ target ];
      };

      isNightly = toolchain.isNightly;
    };
}

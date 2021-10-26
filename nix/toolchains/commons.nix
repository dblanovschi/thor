{ pkgs, lib ? pkgs.lib }:

let
  st = pkgs.rust-bin.stable;
  stl = st.latest;

  bt = pkgs.rust-bin.beta;
  btl = bt.latest;

  nt = pkgs.rust-bin.nightly;
  ntl = nt.latest;

  ttt = { arch, type, os, lib }: "${arch}-${type}-${os}-${lib}";

  createTargetTriple = { arch, type ? "unknown", os, lib }: {
    inherit arch type os lib;

    targetTriple = ttt { inherit arch type os lib; };
  };

  applyOverrideTargetMap = ov: ov // { targets = (map (it: it.targetTriple) ov.targets); };
  util-override = toolchain: profile: override: (profile toolchain).override (applyOverrideTargetMap override);
in
rec {
  targets = rec {
    x86_64-windows-msvc = createTargetTriple { arch = "x86_64"; type = "pc"; os = "windows"; lib = "msvc"; };
    x86_64-windows-gnu = createTargetTriple { arch = "x86_64"; type = "pc"; os = "windows"; lib = "gnu"; };

    x86_64-linux-musl = createTargetTriple { arch = "x86_64"; os = "linux"; lib = "musl"; };
    x86_64-linux-gnu = createTargetTriple { arch = "x86_64"; os = "linux"; lib = "gnu"; };

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

  nightly =
    profile:
    override:
    (pkgs.rust-bin.selectLatestNightlyWith (toolchain: (util-override toolchain profile override)));

  beta-minimal = minimal btl;
  beta-default = default btl;
  beta = util-override btl;

  stable-minimal = minimal stl;
  stable-default = default stl;
  stable = util-override stl;

  from-toolchain = pkgs.rust-bin.fromRustupToolchainFile;

  createToolchain =
    { profile, baseExtensions ? [ ] }:
    { target, toolchain, extraExtensions ? [ ] }: let t = (builtins.trace toolchain toolchain); in {
      inherit target;

      toolchain = t profile {
        extensions = lib.unique (baseExtensions ++ extraExtensions);
        targets = [ target ];
      };

      isNightly = (toolchain == nightly);
    };
}

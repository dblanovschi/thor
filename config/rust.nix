{
  default = {
    enable = false;
    defaultToolchain = "nightly-musl";

    # doctests do not run unless target = host
    # even x86_64-unknown-linux-musl doesn't work when on linux
    # (https://github.com/rust-lang/rust/issues/44404)
    defaultTestTarget = "x86_64-unknown-linux-gnu";
  };

  check = self: pkgs:
    if self.enable && ! pkgs ? rust-bin then
      abort ''
        
        Looks like rust-overlay is missing, but config.rust.enable is set to true.
        Note: Add overlays = [(import (builtins.fetchTarball
            "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"
        ))];
        in import <nixpkgs> {}
      ''
    else self;
}

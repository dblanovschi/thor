{
  default = {
    enable = false;
    defaultToolchain = "nightly-musl";
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

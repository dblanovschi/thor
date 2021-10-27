{ pkgs, lib ? pkgs.lib }:

let
  mergeShells' = shellA: shellB: {
    packages = shellA.packages ++ (shellB.packages or [ ]);
    inputsFrom = shellA.inputsFrom ++ (shellB.inputsFrom or [ ]);
    buildInputs = shellA.buildInputs ++ (shellB.buildInputs or [ ]);
    nativeBuildInputs = shellA.nativeBuildInputs ++ (shellB.nativeBuildInputs or [ ]);

    shellHook = shellA.shellHook + (shellB.shellHook or "") + "\n";
  };

  unique-lize = shell: shell //
    (
      let unique = lib.unique; in
      {
        packages = unique shell.packages;
        inputsFrom = unique shell.inputsFrom;
        buildInputs = unique shell.buildInputs;
        nativeBuildInputs = unique shell.nativeBuildInputs;
      }
    );
in
rec {
  mergeShells = unique-lize lib.foldl mergeShells' {
    packages = [ ];
    inputsFrom = [ ];
    buildInputs = [ ];
    nativeBuildInputs = [ ];

    shellHook = "";
  };

  mkMergedShell = shells: pkgs.mkShell (mergeShells shells);
}

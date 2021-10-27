# for development use in thor only!
# used as an environment for vscode

{pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
    buildInputs = with pkgs; [
        nixpkgs-fmt
    ];
}
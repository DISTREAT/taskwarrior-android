{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [pre-commit];
  shellHook = ''
    pre-commit install --install-hooks
  '';
}

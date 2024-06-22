{
  # inspired by: https://serokell.io/blog/practical-nix-flakes#packaging-existing-applications
  description = "Machine code generator devShell";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.feedback.url = github:NorfairKing/feedback;
  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.xp-asm.url = github:fusion5/xp-asm;

  outputs = { self, nixpkgs, feedback, xp-asm, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          extension = (final: prev: {
            xp-machine-code = final.callCabal2nix "xp-machine-code" ./. {};
            # xp-asm = xp-asm.packages.${system}.xp-asm;
            # FIXME: this works, but why can't we import the package via the
            # flake as above?
            xp-asm = final.callCabal2nix "xp-asm" xp-asm {};
          });
          myHaskellPackages = pkgs.haskellPackages.extend extension;
        in
        {
          packages.xp-machine-code = myHaskellPackages.xp-machine-code;
          defaultPackage = self.packages.${system}.xp-machine-code;
          checks = self.packages;
          test = myHaskellPackages;
          devShell = myHaskellPackages.shellFor {
            # The packages for which to build the development environment
            packages = p: [ p.xp-machine-code ];
            withHoogle = false;
            buildInputs = [
              myHaskellPackages.xp-asm
              myHaskellPackages.haskell-language-server
              myHaskellPackages.ghcid
              myHaskellPackages.cabal-install #TODO: move to nativeBuildInputs?
              feedback.packages.${system}.default
            ];
            # Change the prompt to show that you are in a devShell
            # shellHook = "export PS1='\\e[1;34mdev > \\e[0m'";
          };
        }
      );
}

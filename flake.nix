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
          overlay = (final: prev: {
            xp-machine-code = final.callCabal2nix "xp-machine-code" ./. {};
            xp-asm = xp-asm.packages.${system}.xp-asm;
          });
          myHaskellPackages = pkgs.haskellPackages.extend overlay;
        in
        {
          packages.xp-machine-code = pkgs.haskellPackages.xp-machine-code;
          defaultPackage = self.packages.${system}.xp-machine-code;
          checks = self.packages;
          test = myHaskellPackages;
          devShell = myHaskellPackages.shellFor {
            packages = p: [
              # self.packages.${system}.xp-machine-code
              # xp-asm.packages.${system}.xp-asm
              p.xp-machine-code
              p.xp-asm
              # pkgs.haskellPackages.xp-machine-code
              # (pkgs.haskellPackages.callCabal2nix "xp-machine-code" ./. {})
              # xp-asm.packages.${system}.xp-asm
            ];
            withHoogle = false;
            buildInputs = [
              pkgs.haskellPackages.haskell-language-server
              pkgs.haskellPackages.ghcid
              pkgs.haskellPackages.cabal-install
              feedback.packages.${system}.default
            ];
            # Change the prompt to show that you are in a devShell
            # shellHook = "export PS1='\\e[1;34mdev > \\e[0m'";
          };
        }
      );
}

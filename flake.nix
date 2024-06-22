{
  # inspired by: https://serokell.io/blog/practical-nix-flakes#packaging-existing-applications
  description = "Machine code generator devShell";
  inputs.nixpkgs.url = "nixpkgs";
  inputs.feedback.url = github:NorfairKing/feedback;
  # inputs.xp-asm.url = github:fusion5/xp-asm;

  outputs = { self, nixpkgs, feedback }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = (final: prev: {
        xp-machine-code = final.haskellPackages.callCabal2nix "xp-machine-code" ./. {};
      });
      packages = forAllSystems (system: {
        xp-machine-code = nixpkgsFor.${system}.xp-machine-code;
      });
      defaultPackage = forAllSystems (system: self.packages.${system}.xp-machine-code);
      checks = self.packages;
      devShell = forAllSystems (system: let haskellPackages = nixpkgsFor.${system}.haskellPackages;
        in haskellPackages.shellFor {
          packages = p: [
            self.packages.${system}.xp-machine-code
          ];
          withHoogle = true;
          buildInputs = [
            haskellPackages.haskell-language-server
            haskellPackages.ghcid
            haskellPackages.cabal-install
            feedback.packages.${system}.default
            # xp-asm.packages.${system}.default
          ];
        # Change the prompt to show that you are in a devShell
        # shellHook = "export PS1='\\e[1;34mdev > \\e[0m'";
        });
  };
}

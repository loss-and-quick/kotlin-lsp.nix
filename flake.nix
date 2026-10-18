{
  description = "Nix packaging and flake for JetBrains Kotlin Language Server (kotlin-lsp)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          kotlin-lsp = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.kotlin-lsp;
        }
      );

      apps = eachSystem (
        system: {
          kotlin-lsp = {
            type = "app";
            program = "${self.packages.${system}.kotlin-lsp}/bin/kotlin-lsp";
          };
          default = self.apps.${system}.kotlin-lsp;
        }
      );

      overlays.default = final: prev: {
        kotlin-lsp = final.callPackage ./package.nix { };
      };

      checks = eachSystem (
        system: {
          version = self.packages.${system}.kotlin-lsp.passthru.tests.version;
        }
      );
    };
}

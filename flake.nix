{
  description = "Home Manager configuration of ada";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    packageset.url = "github:mattpolzin/nix-idris2-packages";
    
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      mac-app-util,
      packageset,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      stablePkgs = nixpkgs-stable.legacyPackages.${system};
    in
    {
      homeConfigurations."ada" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          mac-app-util.homeManagerModules.default
          ./home.nix
        ];
        extraSpecialArgs = {
          inherit stablePkgs;
          inherit (packageset.packages.${system})
            idris2
            idris2Lsp
            idris2Packages
            buildIdris
            buildIdris'
            ;
          user = "ada";
          userPackages = [ ];
          extraNushellConfig = "";
        };
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
      homeConfigurations."beatrix" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          mac-app-util.homeManagerModules.default
          ./home.nix
        ];
        extraSpecialArgs = {
          inherit stablePkgs;
          inherit (packageset.packages.${system})
            idris2
            idris2Lsp
            idris2Packages
            buildIdris
            buildIdris'
            ;
          user = "beatrix";
          userPackages = [
            pkgs.coursier
            pkgs.protobuf
            (pkgs.protoc-gen-grpc-java.overrideAttrs (
              oldAttrs:
              let
                baseInputs = oldAttrs.nativeBuildInputs;
              in
              {
                nativeBuildInputs =
                  if pkgs.stdenv.isDarwin then
                    builtins.filter (dep: dep != pkgs.autoPatchelfHook) baseInputs
                  else
                    baseInputs;
              }
            ))
          ];
          extraNushellConfig = "path add '~/Library/Application Support/Coursier/bin'";
        };
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}

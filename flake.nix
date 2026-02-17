{
  description = "Home Manager configuration of ada";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    mac-app-util = {
      url = "github:beatrixada/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.cl-nix-lite.inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    packageset = {
      url = "github:mattpolzin/nix-idris2-packages";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.idris2.inputs.flake-utils.follows = "flake-utils";
      inputs.idris2Lsp.inputs.idris2Lsp.inputs.idris.inputs.flake-utils.follows = "flake-utils";
      inputs.idris2Lsp.inputs.idris2Lsp.inputs.lspLib.follows =
        "packageset/idris2Lsp/lspLib";
    };

  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      mac-app-util,
      packageset,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # https://github.com/nixos/nixpkgs/issues/488689
          # inetutils 2.7 fails to build on aarch64-darwin due to -Wformat-security
          (final: prev: {
            inetutils = prev.inetutils.overrideAttrs (old: rec {
              version = "2.6";
              src = prev.fetchurl {
                url = "mirror://gnu/${old.pname}/${old.pname}-${version}.tar.xz";
                hash = "sha256-aL7b/q9z99hr4qfZm8+9QJPYKfUncIk5Ga4XTAsjV8o=";
              };
            });
          })
        ];
      };
      unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
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
          inherit unstablePkgs;
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
          inherit unstablePkgs;
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

{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-module.nix
      ];
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = {
          utils = pkgs.callPackage ./utils.nix { };
        };
        devShells.default = pkgs.mkShell { packages = [ pkgs.yt-dlp ]; };
      };
      flake = {
        nixosModules.default = import ./module.nix;
      };
    };
}

{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = (import ./pkgs.nix { inherit pkgs; }) // { inherit (pkgs) yt-dlp; };
        devShells.default = pkgs.mkShell { packages = [ pkgs.yt-dlp ]; };
      };
      flake = {
        nixosModules.default = import ./module.nix;
      };
    };
}

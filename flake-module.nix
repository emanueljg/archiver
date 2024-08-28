{ config, flake-parts-lib, ... }: {
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption
      ({ config, options, pkgs, lib, inputs', system, ... }:
        let
          cfg = config.archiver;
        in
        {
          options.archiver = {
            lib =
              let
                archiver-lib = pkgs.callPackage ./lib.nix { };
              in
              {
                writeCompatShellApplication = lib.mkOption {
                  type = with lib.types; functionTo package;
                  default = archiver-lib.writeCompatShellApplication;
                  readOnly = true;
                };
                writeArchiveScript = lib.mkOption {
                  default = archiver-lib.writeArchiveScript;
                  type = with lib.types; functionTo package;
                  readOnly = true;
                };

              };
          };
        });
  };
  config.flake.lib = builtins.mapAttrs (sys: output: output.archiver.lib) config.allSystems;
}



{ config, lib, pkgs, ... }:
let
  cfg = config.services.archiver;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  options.services.archiver = {
    enable = lib.mkEnableOption "archiver";

    user = lib.mkOption {
      type = lib.types.str;
      default = "archiver";
      description = lib.mdDoc ''
        User under archiver runs.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "archiver";
      description = lib.mdDoc ''
        Group under which archiver runs.
      '';
    };

    jobs = lib.mkOption {
      default = [ ];
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          workDir = lib.mkOption {
            type = lib.types.str;
          };
          script = lib.mkOption {
            type = lib.types.package;
          };
        };
      });
    };

  };
  config = lib.mkIf cfg.enable {

    users = {
      users = lib.mkIf (cfg.user == "archiver") {
        archiver = {
          inherit (cfg) group;
          isSystemUser = true;
        };
        groups = lib.mkIf (cfg.group == "archiver") { archiver = { }; };
      };

      systemd = {
        timers."archiver" = {
          timerConfig = {
            OnCalendar = "*-*-* 00:00:00";
            Unit = "archiver.target";
          };
        };
        targets."archiver" = {
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };
        services = lib.mapAttrs'
          (jobName: job: lib.nameValuePair
            "archiver-${jobName}"
            ({
              wantedBy = [ "archiver.target" ];
              after = [ "archiver.target" ];
              path = [ job.script ];
              serviceConfig = {
                ExecStart = lib.getExe job.script;
                User = cfg.user;
                Group = cfg.group;
                ProtectSystem = "strict";
                ProtectHome = "read-only";
                WorkingDirectory = job.workDir; # equivalent to the dir above
                BindReadOnlyPaths = [
                  builtins.storeDir
                  # required for youtube DNS lookup
                  "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
                ];
                CapabilityBoundingSet = "";
                RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
                RestrictNamespaces = true;
                PrivateDevices = true;
                PrivateUsers = true;
                ProtectClock = true;
                ProtectControlGroups = true;
                ProtectKernelLogs = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                SystemCallArchitectures = "native";
                SystemCallFilter = [ "@system-service" "~@privileged" ];
                RestrictRealtime = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                ProtectHostname = true;
              };

            })
          )
          cfg.jobs;
      };
    };
  };
}

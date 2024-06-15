{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.homebox;
  inherit (lib) types;
  toString' = x: if builtins.isBool x then lib.boolToString x else toString x;
  escapeSystemdArg = s: "\"${lib.escape [ "\"" ] s}\"";
  attrsToArgs = lib.flip lib.pipe [
    (lib.filterAttrs (_: x: x != null))
    (lib.mapAttrs (_: toString'))
    (lib.mapAttrsToList (name: value: "--${name}=${value}"))
  ];
in
{
  options.services.homebox = {
    enable = lib.mkEnableOption "homebox";
    package = lib.mkPackageOption pkgs "homebox" { };
    settings = {
      mode = lib.mkOption {
        default = "production";
        type = types.enum [
          "development"
          "production"
        ];
        example = "development";
      };
      web = {
        port = lib.mkOption {
          default = 7745;
          type = types.port;
        };
        host = lib.mkOption {
          default = null;
          type = types.nullOr types.str;
        };
        max-upload-size = lib.mkOption {
          default = 10;
          type = types.ints.positive;
        };
        timeout = {
          read = lib.mkOption {
            default = 10;
            type = types.ints.positive;
          };
          write = lib.mkOption {
            default = 10;
            type = types.ints.positive;
          };
          idle = lib.mkOption {
            default = 30;
            type = types.ints.positive;
          };
        };
      };
      allow-registration = lib.mkOption {
        default = true;
        type = types.bool;
        example = false;
      };
      auto-increment-asset-id = lib.mkOption {
        default = true;
        type = types.bool;
        example = false;
      };
      currency-config = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
      };
      storage = lib.mkOption {
        type = types.path;
        default = "/var/lib/homebox/";
      };
      sqlite-url = lib.mkOption {
        type = types.str;
        default = "/var/lib/homebox/homebox.db?_fk=1";
      };
      log = {
        level = lib.mkOption {
          default = "info";
          type = types.enum [
            "trace"
            "debug"
            "info"
            "warn"
            "error"
            "critical"
          ];
        };
        format = lib.mkOption {
          default = "text";
          type = types.enum [
            "text"
            "json"
          ];
        };
      };
      mailer = {
        enable = lib.mkEnableOption "homebox.mailer";
        port = lib.mkOption {
          default = 587;
          type = types.port;
        };
        host = lib.mkOption { type = types.str; };
      };
      swagger = {
        enable = lib.mkEnableOption "homebox.swagger";
        host = lib.mkOption { default = "localhost"; };
        port = lib.mkOption {
          default = 7745;
          type = types.port;
        };
        schema = lib.mkOption {
          type = lib.enum [
            "http"
            "https"
          ];
        };
      };
      debug = {
        enable = lib.mkEnableOption "homebox.debug";
        port = lib.mkOption {
          default = 4000;
          type = types.port;
        };
      };
    };
    environmentFiles = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      example = [ "/root/homebox.env" ];
      description = lib.mdDoc ''
        File to load environment variables
        from. This is helpful for specifying secrets.
        Example content of environmentFile:
        ```
        HBOX_MAILER_USERNAME=homebox@example.com
        HBOX_MAILER_PASSWORD=password
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ (final: prev: { homebox = final.callPackage ./package.nix { }; }) ];
    systemd.services = {
      homebox = {
        description = "Homebox Service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          DynamicUser = true;
          WorkingDirectory = "%S/homebox";
          StateDirectory = "homebox";
          StateDirectoryMode = "0700";
          UMask = "0007";
          ConfigurationDirectory = "homebox";
          EnvironmentFile = cfg.environmentFiles;
          ExecStart = lib.concatMapStringsSep " " escapeSystemdArg (
            lib.singleton "${cfg.package}/bin/api"
            ++ attrsToArgs (
              {
                inherit (cfg.settings) mode;
                web-port = cfg.settings.web.port;
                web-host = cfg.settings.web.host;
                web-max-upload-size = cfg.settings.web.max-upload-size;
                storage-data = cfg.settings.storage;
                storage-sqlite-url = cfg.settings.sqlite-url;
                log-level = cfg.settings.log.level;
                log-format = cfg.settings.log.format;
                options-allow-registration = cfg.settings.allow-registration;
                options-auto-increment-asset-id = cfg.settings.auto-increment-asset-id;
                options-currency-config = cfg.settings.currency-config;
              }
              // lib.optionalAttrs cfg.settings.mailer.enable {
                mailer-host = cfg.settings.mailer.host;
                mailer-port = cfg.settings.mailer.port;
              }
              // lib.optionalAttrs cfg.settings.swagger.enable {
                swagger-host = "${cfg.settings.swagger.host}:${cfg.settings.swagger.port}";
                swagger-scheme = cfg.settings.swagger.schema;
              }
              // lib.optionalAttrs cfg.settings.debug.enable {
                debug-enabled = cfg.settings.debug.enable;
                debug-port = cfg.settings.debug.port;
              }
            )
          );
          Restart = "on-failure";
          RestartSec = 15;
          CapabilityBoundingSet = "";
          # Security
          NoNewPrivileges = true;
          # Sandboxing
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          PrivateMounts = true;
          # System Call Filtering
          SystemCallArchitectures = "native";
          SystemCallFilter = "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
        };
      };
    };
  };
}

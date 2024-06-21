{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.services.airsane;
  escapeSystemdArg = s: "\"${lib.escape [ "\"" ] s}\"";
  toString' = x: if builtins.isBool x then lib.boolToString x else toString x;
  attrsToArgs = lib.flip lib.pipe [
    (lib.filterAttrs (_: x: x != null))
    (lib.mapAttrs (lib.const toString'))
    (lib.mapAttrsToList (name: value: "--${name}=${value}"))
  ];
in
{
  options.services.airsane = {
    enable = lib.mkEnableOption "airsane";
    package = lib.mkPackageOption pkgs "airsane" { };
    settings = {
      listen-port = lib.mkOption {
        type = types.port;
        default = 8090;
        description = "listening port";
      };
      interface = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "listen on named interface only";
      };
      unix-socket = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "listen on named unix socket";
      };
      access-log = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "HTTP access log, - for stdout";
      };
      hotplug = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "repeat scanner search on hotplug event";
      };
      network-hotplug = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "repeat scanner search on network change";
      };
      mdns-announce = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "announce scanners via mDNS";
      };
      announce-secure = lib.mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "announce secure connection";
      };
      web-interface = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "enable web interface";
      };
      reset-option = lib.mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "allow server reset from web interface";
      };
      disclose-version = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "disclose version information in web interface";
      };
      random-paths = lib.mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "prepend a random uuid to scanner paths";
      };
      compatible-path = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "use /eSCL as path for first scanner";
      };
      local-scanners-only = lib.mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "ignore SANE network scanners";
      };
      job-timeout = lib.mkOption {
        type = types.ints.unsigned;
        default = 120;
        description = "timeout for idle jobs (seconds)";
      };
      purge-interval = lib.mkOption {
        type = types.ints.unsigned;
        default = 5;
        description = "how often job lists are purged (seconds)";
      };
      options-file = lib.mkOption {
        type = types.path;
        default = "${cfg.package}/etc/airsane/options.conf";
      };
      ignore-list = lib.mkOption {
        type = types.path;
        default = "${cfg.package}/etc/airsane/ignore.conf";
      };
      access-file = lib.mkOption {
        type = types.path;
        default = "${cfg.package}/etc/airsane/access.conf";
      };
      debug = lib.mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "log debug information to stderr";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ (final: prev: { airsane = final.callPackage ./package.nix { }; }) ];
    systemd.services.airsaned = {
      description = "AirSane Imaging Service";
      after = [ "avahi-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = lib.concatMapStringsSep " " escapeSystemdArg (
          lib.singleton "${cfg.package}/bin/airsaned" ++ attrsToArgs cfg.settings
        );
        DynamicUser = true;
      };
    };
    # launchd.agents."org.simulpiscator.airsaned" = {
    #   enable = true;
    #   config = {
    #     Label = "org.simulpiscator.airsaned";
    #     KeepAlive = true;
    #     RunAtLoad = true;
    #     ProgramArguments = [ "${cfg.package}/bin/airsaned" ] ++ attrsToArgs cfg.settings;
    #   };
    # };
  };
}

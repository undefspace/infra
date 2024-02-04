{ config, lib, pkgs, ... }:
let
  on = { enable = true; };
  first = a: b: a;
in {
  environment.etc."pipewire/pipewire.conf.d/100-user.conf" = {
    text = builtins.toJSON
      {
        "pulse.properties" = {
          "server.address" = [
            {
              address = "unix:/tmp/pulse"; # address
              client.access = "allowed"; # permissions for clients
            }
            {
              address = "tcp:4713"; # address
              max-clients = 64;                 # maximum number of clients
              listen-backlog = 32;              # backlog in the server listen queue
              client.access = "allowed"; # permissions for clients
            }
          ];
        };
        "context.properties" = {
          "log.level" = 2; # https://docs.pipewire.org/page_daemon.html
        };
        "context.modules" = [
          {
            args = { "nice.level" = -11; };
            flags = [ "ifexists" "nofail" ];
            name = "libpipewire-module-rt";
          }
          { name = "libpipewire-module-profiler"; }
          { name = "libpipewire-module-spa-device-factory"; }
          { name = "libpipewire-module-spa-node-factory"; }
          {
            flags = [ "ifexists" "nofail" ];
            name = "libpipewire-module-portal";
          }
          {
            args = { };
            name = "libpipewire-module-access";
          }
          { name = "libpipewire-module-adapter"; }
          # or else it will see all the macs around it, and switch from time to time
          # { name = "libpipewire-module-raop-discover"; args = { }; }
          { name = "libpipewire-module-link-factory"; }
          { name = "libpipewire-module-session-manager"; }
          {
            name = "libpipewire-module-protocol-pulse";
            args = { };
          }
        ];
      };
  };

  systemd.services.pipewire = {
    serviceConfig.Restart = "always";
    wantedBy = [ "default.target" ];
  };

  services.pipewire = on // {
    audio = on;
    jack = on;
    alsa = on;
    wireplumber = on;
    systemWide = true;
    socketActivation = true;
  };
}

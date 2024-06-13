{ config, lib, pkgs, ... }:
let
  on = { enable = true; };
  first = a: b: a;
in {

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

    extraConfig = {
        pipewire = {
          "100-user" = {
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
          };
        };
      };

    };
}

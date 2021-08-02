{ config, pkgs, ... }: let secrets = pkgs.secrets; in {

  imports = [
    ../core.nix
    ./home-assistant.nix
    ./hardware-configuration.nix
    ./printing.nix
  ];
  networking.hostName = "undef"; # Define your hostname.
  virtualisation.docker.enable = true;

  # for flatpak
  xdg.portal.enable = true;

  # local
  services = let e = { enable = true; }; in {

    syslog-ng = e // {
      extraConfig = ''
      log {
        source {
               network(
                 port(12333)
                 transport("udp")
                 ip("0.0.0.0")
               );
        };
        destination {
          file("/var/log/mowmow-router");
        };
      };
      '';
    };

    # Retroarch on a main screen
    flatpak = e;

    openssh = e // {
      banner = ";; u n d e f s p a c e   w e l c o m e s   y o u ;;\n";
      passwordAuthentication = false;
    };

  };

  security.sudo.wheelNeedsPassword = false;
  users.users.undef = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = secrets.sshKeys;
    extraGroups = [ "wheel" "plugdev" "audio" "lp" "dialout" "scanner" ];
  };
  users.mutableUsers = false;

  environment.systemPackages = with pkgs; [
    wget vim pulsemixer htop spotifyd androidenv.androidPkgs_9_0.platform-tools
  ];

  sound.enable = true;

  # we need goooood audio
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    systemWide = true;
    zeroconf.discovery.enable = true;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true;
    };
    daemon.config = {
      flat-volumes = "no";
    };
  };

}


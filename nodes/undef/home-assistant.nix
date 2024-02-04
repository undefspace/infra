{ config, pkgs, ... }:

let
  mqttUsername = "undef";
in
{

  # Copied over from https://community.home-assistant.io/t/zeroconf-error/153883/3
  boot.kernel.sysctl = {
    # Bigger buffers (to make 40Gb more practical). These are maximums, but the default is unaffected.
    "net.core.wmem_max"=268435456;
    "net.core.rmem_max"=268435456;
    "net.core.netdev_max_backlog"=10000;

    # Avoids problems with multicast traffic arriving on non-default interfaces
    "net.ipv4.conf.default.rp_filter"=0;
    "net.ipv4.conf.all.rp_filter"=0;

    # Force IGMP v2 (required by CBF switch)
    "net.ipv4.conf.all.force_igmp_version"=2;
    "net.ipv4.conf.default.force_igmp_version"=2;

    # Increase the ARP cache table
    "net.ipv4.neigh.default.gc_thresh3"=4096;
    "net.ipv4.neigh.default.gc_thresh2"=2048;
    "net.ipv4.neigh.default.gc_thresh1"=1024;

    # Increase number of multicast groups permitted
    "net.ipv4.igmp_max_memberships"=1024;
  };

  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        ControllerMode = "le";
      };
    };
  };
  virtualisation.podman.enable = true;
  environment.systemPackages = with pkgs; [ podman-compose ];
  # system.activationScripts = {
  #   hassSecrets = "cp /secrets/hass.yaml /var/lib/hass/ && chown hass:hass /var/lib/hass/secrets.yaml";
  #   fixSecretsRights = ''
  #     chown mosquitto:mosquitto /secrets/mqttPassword
  #     chmod +rx /secrets
  #   '';
  # };

  services = let e = { enable = true; };
  in {
    dbus.implementation = "broker";

    printing = e;

    mosquitto = e // {
      listeners = [
        {
          address = "0.0.0.0";
          users = {
            ${mqttUsername} = {
              acl = [ "readwrite #" ];
              passwordFile = "/secrets/mqttPassword";
            };
          };
        }
      ];
    };
  };

}

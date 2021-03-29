{ config, pkgs, ... }:
let
  usecrets = pkgs.secrets.undef;
  mqttUsername = "undef";
  mqttPassword = usecrets.mqttPassword;
in {

  nixpkgs.config.permittedInsecurePackages = [
    "homeassistant-0.114.4"
  ];

  services = let e = { enable = true; };
  in {

    printing = e;
    flatpak = e;

    home-assistant = e // {

      package = (pkgs.home-assistant.overrideAttrs (old: {
        doCheck = false;
        checkPhase = ":";
        installCheckPhase = ":";
      })).override {
        extraComponents =
          [ "esphome" "mpd" "mobile_app" "frontend" "history" "mqtt" ];
      };
      autoExtraComponents = false;

      config = {
        frontend = { };
        mobile_app = { };

        homeassistant = {
          name = "undefspace";
          unit_system = "metric";
          time_zone = "Europe/Moscow";
        };

        history = { include = { domains = [ "sensor" ]; }; };

        mqtt = {
          broker = "localhost";
          discovery = true;
          discovery_prefix = "homeassistant";
          username = mqttUsername;
          password = mqttPassword;
        };

      };

    };

    mosquitto = e // {
      checkPasswords = true;
      users = {
        ${mqttUsername} = {
          acl = [ "topic readwrite #" ];
          password = mqttPassword;
        };
      };
    };
  };

}

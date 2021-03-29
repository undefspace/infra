## core config stuff.
## language, console, base utils -- all that kind of stuff
{ pkgs, ... }:
{

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    colors = [
        "3A3C43" "BE3E48" "869A3A" "C4A535" "4E76A1" "855B8D" "568EA3" "B8BCB9"
        "888987" "FB001E" "0E712E" "C37033" "176CE3" "FB0067" "2D6F6C" "FCFFB8"
    ];
    font = "Lat2-Terminus16";
    useXkbConfig = true; # ctrl:nocaps at last
  };

  services.xserver = {
    layout = "us,ru";
    xkbOptions = "ctrl:nocaps, grp:switch";
  };

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;

  environment.systemPackages = with pkgs; [
    wget vim
  ];

  networking.firewall.enable = false;

  system.stateVersion = "20.09";

}

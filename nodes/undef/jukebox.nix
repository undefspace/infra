{ config, lib, pkgs, ... }:

{
  # Useful for hass playback, and generally less obnoxious with non-apple devices
  services.gmediarender = {
    enable = true;
    friendlyName = "undefdlna";
  };
  systemd.services.gmediarender.environment.PULSE_SERVER = "localhost:4713";

  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      python3Packages.yt-dlp
      mopidy-mpris
      mopidy-soundcloud
      mopidy-youtube
      mopidy-musicbox-webclient
      mopidy-local
      mopidy-mpd
      mopidy-iris
    ];
    configuration = ''
      [local]
      media_dir = /var/lib/mopidy/Music

      [logging]
      verbosity = 4

      [youtube]
      youtube_dl_package = yt_dlp
      allow_cache = true

      [http]
      enabled = true
      hostname = 0.0.0.0
      port = 6680
      zeroconf = Mopidy Instance | Undefspace
      
      [mpris]
      enabled = true
      bus = system

      [mpd]
      hostname = ::
    '';
  };
  users.users.mopidy.extraGroups = [ "pipewire" "audio" "pulse" ];

  systemd.services.shairport-sync = {
    after = [ "pipewire.service" ];
    serviceConfig.RestartSec = "1s";
  };

  services.shairport-sync = {
    enable = true;
    arguments = "-a 'undefaudio' -o pw -S soxr -Mg";
  };
  users.users.shairport.extraGroups = [ "pipewire" ];

}

{ config, pkgs, inputs, ... }: {

  imports = [
    ./core.nix
    ./home-assistant.nix
    ./hardware-configuration.nix
    ./printing.nix
    ./jukebox.nix
    ./pipewire.nix
    # inputs.tg-bot.nixosModule.x86_64-linux
    # ./wg.nix
  ];

  networking = {
    hostName = "undef";
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";
    firewall.enable = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # local
  services = let on = { enable = true; }; in {
    tailscale = on;
    resolved = on;
    iperf3 = on;
    openssh.banner = ";; u n d e f s p a c e   w e l c o m e s   y o u ;;\n";
    # undefspace-tg-bot = e // {
    #   config = "/var/secrets/tg-bot";
    # };
  };

  environment.systemPackages = with pkgs; [
    wget vim pulsemixer htop
  ];

}

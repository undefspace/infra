{ pkgs, ... }: {

  services = let e = { enable = true; }; in {

    # We've got a shared printer connected to it
    printing = e // {
      drivers = with pkgs; [
        gutenprint
        hplip
      ];
      listenAddresses = [ "*:631" ];
      startWhenNeeded = false;
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
    };
    saned = e // {
      # Allows all incoming connections
      extraConfig = "+";
    };

    avahi = e // {
      publish = e // {
        domain = true;
        userServices = true;
      };
   };

  };

  users.users.scanner.extraGroups = [ "lp" "avahi" ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "YES-WE-DO-HAVE-A-PRINTER";
        deviceUri = "hp:/usb/DeskJet_2130_series?serial=CN6AB4931P067S";
        model = "HP/hp-deskjet_2130_series.ppd.gz";
        location = "main hall";
        description = "only prints b/w for now";
      }
    ];
    ensureDefaultPrinter = "YES-WE-DO-HAVE-A-PRINTER";
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      hplip
    ];
  };

}


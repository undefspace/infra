{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixops.url = "github:nixos/nixops";
    nixops.inputs.nixpkgs.follows = "nixpkgs";
    tg-bot.url = "github:undefspace/tg-bot";
    tg-bot.inputs.nixpkgs.follows = "nixpkgs";

    secrets.flake = false;
    secrets.url = "flake:undefspace-secrets";
  };

  outputs = inputs @ { self, nixpkgs, nixops, secrets, tg-bot, ... }: {
    nixopsConfigurations =
      let
        locsec = import "${secrets}/secrets.nix";
      in
      {
      default = {
        inherit nixpkgs;

        require = [
          42 # WHY WON'T YOU BREAK
        ];

        defaults = {
          users.users.root.openssh.authorizedKeys.keys = locsec.sshKeys;
        };


        network.storage.legacy = {
          databasefile = "~/.nixops/deployments.nixops";
        };

        undef = {

          deployment = {
            targetHost = "10.98.6.59";#"10.98.32.44";#"10.0.10.8";
            hasFastConnection = true;
          };

          # Ouch.
          nixpkgs.overlays = [
            (self: super: {
              secrets = import "${secrets}/secrets.nix";
              all-secrets = secrets;
            })
          ];

          services.undefspace-tg-bot = {
            enable = true;
            config = "/var/secrets/tg-bot";
          };

          imports = [ ./undef "${secrets}/wg.nix" tg-bot.nixosModule.x86_64-linux ];
        };

      };

    };

    devShell.x86_64-linux = with nixpkgs.legacyPackages.x86_64-linux; mkShell {
      buildInputs = [ nixops.defaultPackage.x86_64-linux nixfmt sops ];
    };

  };

}

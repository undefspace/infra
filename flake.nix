{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixops.url = "github:cab404/nixops/patch-1";
    nixops.inputs.nixpkgs.follows = "nixpkgs";
    secrets.flake = false;
    secrets.url = "flake:undefspace-secrets";
  };

  outputs = inputs @ { self, nixpkgs, nixops, secrets, ... }: {
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

        undef = {
          deployment = {
            targetHost = "10.0.10.8";
          };

          # Ouch.
          nixpkgs.overlays = [
            (self: super: { secrets = import "${secrets}/secrets.nix"; })
          ];

          imports = [ ./undef "${secrets}/wg.nix" ];
        };

      };

    };

    devShell.x86_64-linux = with nixpkgs.legacyPackages.x86_64-linux; mkShell {
      buildInputs = [ nixops.defaultPackage.x86_64-linux nixfmt sops ];
    };

  };

}

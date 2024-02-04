{
  description = "Undefspace infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # tg-bot.url = "github:undefspace/tg-bot";
    # tg-bot.inputs.nixpkgs.follows = "nixpkgs";

    terranix.url = "github:terranix/terranix";

    wg-bond.url = "github:cab404/wg-bond";
    wg-bond.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, terranix, deploy-rs, wg-bond, ... }:
    with builtins; let

      shellSystems = attrNames deploy-rs.packages;

      # Nixpkgs level
      foldAttrs = foldl' (a: b: a // b) { };
      systemPkgs = nixpkgs.legacyPackages;
      shellPkgs = peekAttrset systemPkgs shellSystems;
      peekAttrset = attrs: names: foldAttrs (map (n: { ${n} = attrs.${n}; }) names);
      onPkgs = f: mapAttrs f systemPkgs;
      onShellPkgs = f: mapAttrs f shellPkgs;

      # System level

      inherit (nixpkgs) lib;
      specialArgs = { inherit inputs; };
      buildConfig = system: modules: { inherit modules system specialArgs; };
      buildSystem = system: modules:
        lib.nixosSystem (buildConfig system modules);
      deployNixos = s: deploy-rs.lib.${s.pkgs.system}.activate.nixos s;
      deployHomeManager = sys: s: deploy-rs.lib.${sys}.activate.home-manager s;

      # Node level
      hosts = attrNames (readDir ./nodes);
      hostAttrs = hostname: {
        settings = import ./nodes/${hostname}/host-metadata.nix;
        config = import ./nodes/${hostname}/configuration.nix;
        hw-config = import ./nodes/${hostname}/hardware-configuration.nix;
      };

      toNode = hostname: with (hostAttrs hostname); buildSystem settings.system [
        config
        ({ lib, ... }: { networking.hostName = hostname; })
        ./common/configuration.nix
        hw-config
      ];

      toVM = hostname: with (hostAttrs hostname); (buildSystem settings.arch [
        config
        ({ lib, ... }: { networking.hostName = hostname; })
        ./common/configuration.nix
        (nixpkgs + /nixos/modules/virtualisation/build-vm.nix)
      ]).config.system.build.vm;

      toDeployRsHost = hostname: with (hostAttrs hostname); {
        hostname = settings.hostname;
        profiles.system = { path = deployNixos (toNode hostname); user = "root"; };
      };

    in {

      packages = onShellPkgs (system: pkgs: {
        terraform-config = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [ ./terraform ];
        };
      } // foldAttrs (map (hostname: { ${hostname} = toVM hostname; }) hosts));

      devShells = onShellPkgs (system: pkgs: {
        default = with pkgs;
          mkShell {
            nativeBuildInputs = [
              # Nix formatter
              nixpkgs-fmt
              # Nix config deployment utility
              # deploy-rs.packages.${system}.default
              # Terraform
              # terraform
              # vault
              gnumake

              # inputs.wg-bond.defaultPackage.${system}
            ];
          };
      });

      nixosConfigurations = foldAttrs (map (hostname: { ${hostname} = toNode hostname; }) hosts);

      deploy = {
        sshUser = "root";
        nodes = foldAttrs (map (hostname: { ${hostname} = toDeployRsHost hostname; }) hosts);
      };

      # deploy = {
      #   nodes = {
      #     undef = {
      #       hostname = "undef.lan";
      #       profiles = {
      #         system = {
      #           user = "root";
      #           path = deployNixos (buildSystem [ ./undef ]);
      #         };
      #       };
      #     };
      #     twob = {
      #       hostname = "twob.lan";
      #       profiles = {
      #         system = {
      #           user = "root";
      #           path = deployNixos (buildSystem [ ./twob/configuration.nix ]);
      #         };
      #       };
      #     };
      #     cabriolet = {
      #       hostname = "cock.undef.club";
      #       profiles = {
      #         system = {
      #           user = "root";
      #           path = deployNixos (buildSystem [ ./twob ]);
      #         };
      #       };
      #     };
      #   };
      # };
    };

}

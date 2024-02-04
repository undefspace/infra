let
  sshKeysFile = import ./sshKeys.nix;
in {
  users.users.root = { openssh.authorizedKeys.keys = sshKeysFile.sshKeys; };
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };
}

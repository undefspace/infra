## core config stuff.
## language, console, base utils -- all that kind of stuff
{ pkgs, ... }:
{
  networking.firewall.enable = false;
  system.stateVersion = "23.05";
}

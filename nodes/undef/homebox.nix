{ ... }:
{
  services.homebox = {
    enable = true;
    settings.log.format = "json";
    settings.allow-registration = false;
  };
}

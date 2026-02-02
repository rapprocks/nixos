{
  lib,
  config,
  username,
  ...
}:
let
  cfg = config.profiles.tailnet;
in
{
  options.profiles.tailnet.enable = lib.mkEnableOption "Enable tailnet access";

  config = lib.mkIf cfg.enable {

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraSetFlags = [ "--operator=${username}" ];
    };

  };
}

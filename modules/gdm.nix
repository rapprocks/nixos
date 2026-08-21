{
  lib,
  config,
  username,
  ...
}:
let
  cfg = config.profiles.gdm;
in
{
  options.profiles.gdm = {
    enable = lib.mkEnableOption "GDM";
    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GDM autologin.";
    };
  };

  config = lib.mkIf config.profiles.gdm.enable {
    services.displayManager.gdm.enable = true;

    services.displayManager.autoLogin = lib.mkIf cfg.autoLogin {
      enable = true;
      user = username;
    };
  };
}

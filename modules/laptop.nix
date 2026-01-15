{
  lib,
  config,
  ...
}: let
  cfg = config.profiles.laptop;
in {
  options.profiles.laptop.enable = lib.mkEnableOption "laptop power management and lid handling";

  config = lib.mkIf cfg.enable {
    services.logind.settings.Login = {
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
    };

    services.power-profiles-daemon.enable = false;

    services.auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "auto";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };
}
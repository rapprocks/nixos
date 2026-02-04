{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  cfg = config.profiles.displayManager;
in
{
  options.profiles.displayManager = {
    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Auto-login to Niri (for LUKS-encrypted hosts that already authenticated at boot)";
    };
  };

  config = {
    services.greetd = {
      enable = true;
      settings = {
        default_session =
          if cfg.autoLogin then
            {
              # LUKS hosts: skip greeter, go straight to Niri
              command = "niri-session";
              user = username;
            }
          else
            {
              # Non-LUKS hosts: show tuigreet for authentication
              command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
              user = "greeter";
            };
      };
    };

    # Suppress greetd errors in journal (optional, cleaner logs)
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}

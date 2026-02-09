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
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
          user = "greeter";
        };
      } // lib.optionalAttrs cfg.autoLogin {
        initial_session = {
          command = "niri-session";
          user = username;
        };
      };
    };

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
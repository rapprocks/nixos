{
  lib,
  config,
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
          command = "niri-session";
          user = username;
        };
      }
      // lib.optionalAttrs cfg.autoLogin {
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

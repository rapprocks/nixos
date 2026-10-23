{ ... }:
{
  flake.nixosModules.displayManager =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.services.dm.greetd;
    in
    {
      options.services.dm.greetd = {
        enable = lib.mkEnableOption "greetd";
        autoLogin = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Auto-login to Niri (for LUKS-encrypted hosts that already authenticated at boot)";
        };
        autoLoginUser = lib.mkOption {
          type = lib.types.str;
          default = "earn";
          description = "Username to automatically log into when autoLogin is enabled.";
        };
        # Shared greeter command, so every login screen (tty1, tty2) looks the same.
        greeterCommand = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
          description = "Command that starts the login greeter.";
        };
      };

      config = lib.mkIf config.services.dm.greetd.enable {
        assertions = [
          {
            assertion =
              !cfg.autoLogin
              || lib.length (lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users)) <= 1;
            message = "services.dm.greetd.autoLogin must be false on hosts with more than one user.";
          }
        ];

        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = cfg.greeterCommand;
              user = "greeter";
            };
          }
          // lib.optionalAttrs cfg.autoLogin {
            initial_session = {
              command = "niri-session";
              user = cfg.autoLoginUser;
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
    };
}

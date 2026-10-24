{ inputs, ... }: {
  flake.nixosModules.system = { config, lib, ... }: {
    imports = [
      inputs.fingerprint-lid-guard.nixosModules.default
    ];

    options.hardware.laptop.enable = lib.mkEnableOption "laptop power management, lid-switch handling, and fingerprint reader with lid guard";

    config = lib.mkMerge [
      {
        nixpkgs.config.allowUnfree = true;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 1d";
        };

        programs.nix-ld.enable = true;

        networking.networkmanager.enable = true;
        services.openssh.enable = true;

        # Set your time zone.
        time.timeZone = "Europe/Stockholm";

        # Select internationalisation properties.
        i18n.defaultLocale = "en_US.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "sv_SE.UTF-8";
          LC_IDENTIFICATION = "sv_SE.UTF-8";
          LC_MEASUREMENT = "sv_SE.UTF-8";
          LC_MONETARY = "sv_SE.UTF-8";
          LC_NAME = "sv_SE.UTF-8";
          LC_NUMERIC = "sv_SE.UTF-8";
          LC_PAPER = "sv_SE.UTF-8";
          LC_TELEPHONE = "sv_SE.UTF-8";
          LC_TIME = "sv_SE.UTF-8";
        };

        # Configure keymap in X11
        services.xserver.xkb = {
          layout = "se";
          variant = "nodeadkeys";
        };

        # Configure console keymap
        console.keyMap = "sv-latin1";
      }

      (lib.mkIf config.hardware.laptop.enable {
        services.power-profiles-daemon.enable = true;
        services.thermald.enable = config.hardware.cpu.intel.updateMicrocode;
        powerManagement.powertop.enable = false;

        services.logind.settings.Login = {
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "lock";
        };

        services.fprintd = {
          enable = true;
          lid-guard = {
            enable = true;
            extraPamServices = [ "hyprlock" ];
          };
        };
      })
    ];
  };
}

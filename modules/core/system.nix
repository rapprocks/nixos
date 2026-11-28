{ ... }: {
  flake.nixosModules.system = { config, lib, ... }: {
    options.hardware.laptop.enable = lib.mkEnableOption "laptop power management, lid-switch handling, and fingerprint reader";

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

        services.fprintd.enable = true;

        # The Goodix MOC sensor (27c6:609c) is runtime-autosuspended after 2s by
        # libfprint's hwdb entry. After s2idle resume the first verify then hits a
        # sleeping sensor and fails with "transfer timed out", which makes
        # hyprlock print "Fingerprint auth disabled (unknown error)" for that lock.
        # Keep the sensor powered. Runs after 60-autosuspend.rules, so it wins.
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="27c6", ATTR{idProduct}=="609c", ATTR{power/control}="on"
        '';

        # fprintd is normally D-Bus activated by hyprlock, which hypridle starts
        # from before_sleep_cmd *after* logind has begun suspending. fprintd then
        # cannot take its sleep delay inhibitor ("OperationInProgress"), never
        # suspends/resumes the Goodix sensor cleanly, and leaves a stale claim.
        # Keeping it running from boot makes it hold the inhibitor before sleep.
        systemd.services.fprintd = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig.ExecStart = [
            ""
            "${config.services.fprintd.package}/libexec/fprintd --no-timeout"
          ];
        };
      })
    ];
  };
}

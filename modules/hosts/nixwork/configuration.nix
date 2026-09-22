{ self, inputs, ... }: {
  flake.nixosConfigurations.nixwork = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.nixworkConfig ];
  };

  flake.nixosModules.nixworkConfig = { pkgs, ... }: {
    imports = [
      self.nixosModules.nixworkHardware
      self.nixosModules.workstation
      self.nixosModules.work
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
    ]
    ++ [
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
      inputs.fingerprint-lid-guard.nixosModules.default
    ];

    environment.systemPackages = with pkgs; [
      ngrok
    ];

    networking.hostName = "nixwork";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."luks-e23c56ef-712d-4c70-9b40-525e09217a72".device =
      "/dev/disk/by-uuid/e23c56ef-712d-4c70-9b40-525e09217a72";

    # Machine-specific graphics and power policy.
    powerManagement.powertop.enable = false;

    # Lid-switch behavior for laptop.
    services.logind.settings.Login = {
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
    };

    services.fprintd.lid-guard = {
      enable = true;
      # lidPath = "LID0"; # override if your ACPI device has a different name
      # pamServices = [...]; # override if you want to choose the PAM services selectively
      extraPamServices = [
        "hyprlock" # or any other PAM services not in the default list
      ];
    };

    programs.zsh.shellInit = ''
      export PATH="$HOME/.local/bin:$PATH"
      eval "$(aw autocomplete:script zsh)"
    '';

    # Enable Wi-Fi and Syncthing for this work host
    networking.enabledWifiNetworks = [
      "k69"
      "work"
    ];

    services.virtualisation.enable = true;
    services.docker.enable = true;
    services.dm.greetd = {
      enable = true;
      autoLogin = true;
    };

    services.syncthingSync = {
      enable = true;
      folders = {
        "wallpapers" = {
          id = "wallpapers";
          path = "/home/earn/Pictures/wallpapers";
          devices = [
            "zeus"
            "nixwork"
          ];
        };
      };
    };

    # Additions specific to this host; shared mappings live with their features.
    services.dotfiles = {
      mappings = {
        ".config/waybar/config.jsonc" = "waybar/2027.jsonc";
        ".config/waybar/style.css" = "waybar/2027.css";
        ".config/herdr/config.toml" = "herdr/config.toml";
        ".config/opencode/themes" = "opencode/themes";
        ".gitconfig" = ".gitconfig";

        ".config/hypr/hypridle.conf" = "hypr/hypridle.conf";
        ".config/hypr/hyprlock.conf" = "hypr/hyprlock.conf";
      };
      themedMappings.".config/waybar/colors.css" = {
        dark = "waybar/rose-pine.css";
        light = "waybar/rose-pine-dawn.css";
      };
    };
  };
}

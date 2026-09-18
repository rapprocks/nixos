{ self, inputs, ... }: {
  flake.nixosConfigurations.nixwork = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.nixworkConfig ];
  };

  flake.nixosModules.nixworkConfig = { config, ... }: {
    imports =
      with self.nixosModules;
      [
        nixworkHardware
        workstation
        slimniri
        firefox
        nasMounts
      ]
      ++ [ inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series ];

    networking.hostName = "nixwork";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."luks-e23c56ef-712d-4c70-9b40-525e09217a72".device =
      "/dev/disk/by-uuid/e23c56ef-712d-4c70-9b40-525e09217a72";

    # Machine-specific graphics and power policy.
    #services.power-profiles-daemon.enable = true;
    #services.thermald.enable = true;
    powerManagement.powertop.enable = false;

    sops.secrets."wifi_k69" = { };
    sops.templates."wifi.env".content = ''
      WIFI_K69_PSK=${config.sops.placeholder.wifi_k69}
    '';
    networking.wireless.iwd.enable = true;
    networking.networkmanager = {
      wifi.backend = "iwd";
      ensureProfiles = {
        environmentFiles = [ config.sops.templates."wifi.env".path ];
        profiles."k69" = {
          connection = {
            id = "k69";
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = "k69";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$WIFI_K69_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
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
      };
      themedMappings.".config/waybar/colors.css" = {
        dark = "waybar/rose-pine.css";
        light = "waybar/rose-pine-dawn.css";
      };
    };
  };
}

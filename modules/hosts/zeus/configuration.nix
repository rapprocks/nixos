{ self, inputs, ... }: {
  flake.nixosConfigurations.zeus = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.zeusConfig ];
  };

  flake.nixosModules.zeusConfig = { pkgs, ... }: {
    imports = [
      self.nixosModules.zeusHardware
      self.nixosModules.workstation
      self.nixosModules.personal
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
    ];

    networking.hostName = "zeus";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."nixos".device = "/dev/disk/by-uuid/0a6f4373-9f5f-4e40-bea3-e953009834c3";

    # Machine-specific graphics and power policy.
    boot.initrd.kernelModules = [ "i915" ];
    boot.kernelParams = [ "i915.force_probe=a7a1" ];
    hardware.graphics.extraPackages = [ pkgs.vpl-gpu-rt ];
    services.power-profiles-daemon.enable = true;
    services.thermald.enable = true;
    powerManagement.powertop.enable = false;

    # Enable Wi-Fi and Syncthing for this personal host
    networking.enabledWifiNetworks = [ "k69" ];
    services.syncthingSync = {
      enable = true;
      folders = {
        "notes" = {
          id = "notes";
          path = "/home/earn/Documents/notes";
          devices = [ "zeus" ];
        };
        "wallpapers" = {
          id = "wallpapers";
          path = "/home/earn/Pictures/wallpapers";
          devices = [ "zeus" ];
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

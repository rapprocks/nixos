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

    preferences.host.name = "zeus";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."nixos".device = "/dev/disk/by-uuid/0a6f4373-9f5f-4e40-bea3-e953009834c3";

    # Machine-specific graphics and power policy.
    boot.initrd.kernelModules = [ "i915" ];
    boot.kernelParams = [ "i915.force_probe=a7a1" ];
    hardware.graphics.extraPackages = [ pkgs.vpl-gpu-rt ];
    hardware.laptop.enable = true;

    # Enable Wi-Fi and Syncthing for this personal host
    networking.enabledWifiNetworks = [ "k69" ];
    services.syncthingSync = {
      enable = true;
      folders = {
        "notes" = {
          id = "notes";
          path = "~/Documents/notes";
          devices = [
            "apollo"
            "zeus"
            "truenas"
          ];
        };
        "wallpapers" = {
          id = "wallpapers";
          path = "~/Pictures/wallpapers";
          devices = [
            "apollo"
            "zeus"
            "truenas"
            "nixwork"
          ];
        };
      };
    };
  };
}

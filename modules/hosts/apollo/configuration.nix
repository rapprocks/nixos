{ self, inputs, ... }: {
  flake.nixosConfigurations.apollo = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.apolloConfig ];
  };

  flake.nixosModules.apolloConfig = { ... }: {
    imports = [
      self.nixosModules.apolloHardware
      self.nixosModules.workstation
      self.nixosModules.personal
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
    ]
    ++ [
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-pc-ssd
      inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
      inputs.nixos-hardware.nixosModules.common-gpu-amd
    ];

    networking.hostName = "apollo";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    services.syncthingSync = {
      enable = true;
      folders = {
        "notes" = {
          id = "notes";
          path = "/home/earn/Documents/notes";
          devices = [
            "zeus"
            "truenas"
          ];
        };
        "wallpapers" = {
          id = "wallpapers";
          path = "/home/earn/Pictures/wallpapers";
          devices = [
            "zeus"
            "truenas"
            "nixwork"
          ];
        };
      };
    };
  };
}

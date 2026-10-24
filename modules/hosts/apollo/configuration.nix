{ self, inputs, ... }: {
  flake.nixosConfigurations.apollo = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.apolloConfig ];
  };

  flake.nixosModules.apolloConfig = { ... }: {
    imports = [
      #self.nixosModules.apolloHardware
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

    # Enable Wi-Fi and Syncthing for this personal host after initial rebuild and SOPS setup
    #networking.enabledWifiNetworks = [ "k69" ];
    #services.syncthingSync = {
    #  enable = true;
    #  folders = {
    #    "notes" = {
    #      id = "notes";
    #      path = "/home/earn/Documents/notes";
    #      devices = [
    #        "apollo"
    #        "zeus"
    #        "truenas"
    #      ];
    #    };
    #    "wallpapers" = {
    #      id = "wallpapers";
    #      path = "/home/earn/Pictures/wallpapers";
    #      devices = [
    #        "apollo"
    #        "zeus"
    #        "truenas"
    #        "nixwork"
    #      ];
    #    };
    #  };
    #};
  };
}

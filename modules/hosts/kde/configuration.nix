{ self, inputs, ... }: {
  flake.nixosConfigurations.kde = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.kdeConfig ];
  };

  flake.nixosModules.kdeConfig = { ... }: {
    imports = with self.nixosModules; [
      kdeHardware
      workstation
      slimniri
      firefox
      nasMounts
    ];

    networking.hostName = "kde";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}

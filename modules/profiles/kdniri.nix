{ self, ... }: {
  flake.nixosModules.kdniri = { ... }: {
    imports = [
      self.nixosModules.dms
      self.nixosModules.plasma
      self.nixosModules.niri
    ];
  };
}

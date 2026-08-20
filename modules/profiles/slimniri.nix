{ self, ... }: {
  flake.nixosModules.slimniri = { ... }: {
    imports = [
      self.nixosModules.niri
      self.nixosModules.swayidle
      self.nixosModules.greetd
    ];
  };
}

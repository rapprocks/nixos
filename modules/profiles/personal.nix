{ self, ... }:
{
  flake.nixosModules.personal = { ... }: {
    imports = with self.nixosModules; [
      nasMounts
    ];

    # TODO: Add personal-only settings here as needed
  };
}

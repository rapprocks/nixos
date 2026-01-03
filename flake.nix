{
  description = "FLAKES3000";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixvim.url = "github:rapprocks/nixvim/main";
    #pvetui.url = "git+https://github.com/devnullvoid/pvetui?ref=master";
  };

  outputs = {
    self,
    nixpkgs,
    nixvim,
    #pvetui,
    ...
  } @ inputs: {
    nixosConfigurations = {
      nix = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          {
            nixpkgs.hostPlatform = "x86_64-linux";
            nixpkgs.config.allowUnfree = true;
          }
          ./machines/common.nix
          ./machines/nixlab/configuration.nix
        ];
      };
      apollo = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          {
            nixpkgs.hostPlatform = "x86_64-linux";
            nixpkgs.config.allowUnfree = true;
          }
          ./machines/common.nix
          ./machines/apollo/configuration.nix
        ];
      };
      zeus = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          {
            nixpkgs.hostPlatform = "x86_64-linux";
            nixpkgs.config.allowUnfree = true;
          }
          ./machines/common.nix
          #./machines/zeus/configuration.nix
        ];
      };
    };
  };
}

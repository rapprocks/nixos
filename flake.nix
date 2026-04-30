{
  description = "FLAKES3000";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/4bd9165a9165d7b5e33ae57f3eecbcb28fb231c9";
    nixvim.url = "github:rapprocks/nixvim/main";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      mkHost =
        {
          hostname,
          username,
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs username; };
          modules = [
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              nixpkgs.config.allowUnfree = true;
            }
            ./modules
            ./machines/common.nix
            ./machines/${hostname}/configuration.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        nixwrk = mkHost {
          hostname = "nixwrk";
          username = "philip";
        };
        apollo = mkHost {
          hostname = "apollo";
          username = "earn";
        };
        zeus = mkHost {
          hostname = "zeus";
          username = "earn";
        };
      };
    };
}

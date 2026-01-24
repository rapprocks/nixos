{
  description = "FLAKES3000";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:rapprocks/nixvim/main";

    dms.url = "github:AvengeMedia/DankMaterialShell/stable";
    dms.inputs.nixpkgs.follows = "nixpkgs";
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

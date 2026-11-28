{ self, inputs, ... }:
{
  flake.nixosModules.personal =
    { pkgs, ... }:
    {
      imports = with self.nixosModules; [
        nasMounts
      ];

      environment.systemPackages = with pkgs; [
        blender
        orca-slicer
        gimp
        freecad
        inputs.solidcraft.packages.${pkgs.stdenv.hostPlatform.system}.solidcraft
      ];

      services.dm.greetd = {
        enable = true;
        autoLogin = true;
      };

      services.desktopApps = {
        "feedly" = {
          enable = true;
          sourcePath = "~/.dotfiles/apps/feedly.desktop";
          iconPath = "~/.dotfiles/apps/icons/feedly.png";
        };
        "x" = {
          enable = true;
          sourcePath = "~/.dotfiles/apps/x.desktop";
          iconPath = "~/.dotfiles/apps/icons/x.png";
        };
      };

      services.syncthingSync = {
        enable = true;
        folders = {
          "vault" = {
            id = "vault";
            path = "~/vault";
            devices = [
              "apollo"
              "zeus"
              "truenas"
            ];
          };
        };
      };

      services.dotfiles.mappings = {
        ".config/waybar/group-center.jsonc" = "waybar/group-center.jsonc";
        ".pi/agent/APPEND_SYSTEM.md" = "pi/agent/APPEND_SYSTEM.md";
      };
    };
}

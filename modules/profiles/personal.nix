{ self, ... }:
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

      services.dotfiles.mappings = {
        ".config/waybar/group-center.jsonc" = "waybar/group-center.jsonc";
      };
    };
}

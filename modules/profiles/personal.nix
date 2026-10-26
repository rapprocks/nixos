{ self, inputs, ... }:
{
  flake.nixosModules.personal =
    { pkgs, ... }:
    {
      imports = with self.nixosModules; [
        nasMounts
      ];

      nixpkgs.overlays = [
        (final: prev: {
          # Work around nixpkgs regression (fixed upstream) where vtk_9_5
          # renamed VTK::pegtl -> VTK::vtkpegtl in postPatch while still passing
          # -DVTK_MODULE_USE_EXTERNAL_VTK_pegtl=FALSE.
          vtk_9_5 = prev.vtk_9_5.overrideAttrs { postPatch = ""; };
        })
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

      services.dotfiles.mappings = {
        ".config/waybar/group-center.jsonc" = "waybar/group-center.jsonc";
      };
    };
}

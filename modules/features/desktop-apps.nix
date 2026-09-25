{ ... }: {
  flake.nixosModules.desktopApps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.desktopApps;

      # Symlinks require absolute paths to work correctly in the system profile.
      # We expand ~/ to your actual home directory string.
      expandHome =
        path: if lib.hasPrefix "~/" path then "/home/earn/" + lib.removePrefix "~/" path else path;

    in
    {
      options.services.desktopApps = lib.mkOption {
        description = "Symlink custom desktop applications from dotfiles.";
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "this desktop app";

              sourcePath = lib.mkOption {
                type = lib.types.str;
                description = "Path to the .desktop file. Supports ~/ prefix.";
              };

              iconPath = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Optional path to the icon file (.png or .svg). Supports ~/ prefix.";
              };
            };
          }
        );
      };

      config = lib.mkIf (cfg != { }) {
        environment.systemPackages = lib.mapAttrsToList (
          name: app:
          pkgs.runCommand "${name}-desktop-entry" { } ''
            mkdir -p $out/share/applications
            ln -s "${expandHome app.sourcePath}" $out/share/applications/${name}.desktop

            ${lib.optionalString (app.iconPath != null) ''
              expandedIconPath="${expandHome app.iconPath}"
              iconExt="''${expandedIconPath##*.}"

              # Route SVGs to scalable, PNGs to 256x256
              if [ "$iconExt" = "svg" ]; then
                targetDir="$out/share/icons/hicolor/scalable/apps"
              else
                targetDir="$out/share/icons/hicolor/256x256/apps"
              fi

              mkdir -p "$targetDir"
              ln -s "$expandedIconPath" "$targetDir/${name}.$iconExt"
            ''}
          ''
        ) (lib.filterAttrs (n: v: v.enable) cfg);
      };
    };
}

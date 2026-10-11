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
      enabledApps = lib.filterAttrs (_: app: app.enable) cfg;
      # Create directories as the user so ownership of ~/.local stays correct.
      runAsUser = ''${pkgs.util-linux}/bin/runuser -u "$U" --'';

      # Paths are resolved at activation time against each user's own home,
      # so every user gets entries pointing into their own dotfiles clone.
      expandHome =
        path: if lib.hasPrefix "~/" path then "$U_HOME/" + lib.removePrefix "~/" path else path;

      linkApp = name: app: ''
        ${runAsUser} mkdir -p "$U_HOME/.local/share/applications"
        ln -sfn "${expandHome app.sourcePath}" "$U_HOME/.local/share/applications/${name}.desktop"
        chown -h "$U:$U_GROUP" "$U_HOME/.local/share/applications/${name}.desktop"
        ${lib.optionalString (app.iconPath != null) ''
          ICON_PATH="${expandHome app.iconPath}"
          if [ "''${ICON_PATH##*.}" = "svg" ]; then
            ICON_DIR="$U_HOME/.local/share/icons/hicolor/scalable/apps"
          else
            ICON_DIR="$U_HOME/.local/share/icons/hicolor/256x256/apps"
          fi
          ${runAsUser} mkdir -p "$ICON_DIR"
          ln -sfn "$ICON_PATH" "$ICON_DIR/${name}.''${ICON_PATH##*.}"
          chown -h "$U:$U_GROUP" "$ICON_DIR/${name}.''${ICON_PATH##*.}"
        ''}
      '';

      linkForUser = u: ''
        if id "${u}" >/dev/null 2>&1; then
          U="${u}"
          U_HOME="$(getent passwd "$U" | cut -d: -f6)"
          U_GROUP="$(id -gn "$U")"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList linkApp enabledApps)}
        fi
      '';
    in
    {
      options.services.desktopApps = lib.mkOption {
        description = "Link custom desktop applications from each user's dotfiles clone.";
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "this desktop app";

              sourcePath = lib.mkOption {
                type = lib.types.str;
                description = "Path to the .desktop file. ~/ resolves to each user's home.";
              };

              iconPath = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Optional path to the icon file (.png or .svg). ~/ resolves to each user's home.";
              };
            };
          }
        );
      };

      config = lib.mkIf (enabledApps != { }) {
        system.activationScripts.desktopAppsLink = {
          deps = [ "dotfilesSync" ];
          text = lib.concatStringsSep "\n" (
            map linkForUser (lib.attrNames config.services.dotfiles.users)
          );
        };
      };
    };
}

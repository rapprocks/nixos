{ ... }:
{
  flake.nixosModules.dotfiles =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.dotfiles;
      user = config.users.users.${cfg.user};
      homeDir = user.home;
      dotfilesDir = "${homeDir}/.dotfiles";
      # Generated user command: theme-switcher [dark|light|toggle]
      themeSwitcher = pkgs.writeShellScriptBin "theme-switcher" ''
        THEME_STATE_FILE="${homeDir}/.config/theme_mode"
        MODE="$1"
        if [ -z "$MODE" ] || [ "$MODE" = "toggle" ]; then
          if [ -f "$THEME_STATE_FILE" ] && [ "$(cat "$THEME_STATE_FILE" | tr -d ' \n\r')" = "dark" ]; then
            MODE="light"
          else
            MODE="dark"
          fi
        fi
        if [ "$MODE" != "dark" ] && [ "$MODE" != "light" ]; then
          echo "Usage: theme-switcher [dark|light|toggle]"
          exit 1
        fi
        echo "Switching theme to $MODE..."
        echo "$MODE" > "$THEME_STATE_FILE"
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (target: themeSources: ''
            TARGET_PATH="${homeDir}/${target}"
            if [ "$MODE" = "light" ]; then
              SOURCE_PATH="${dotfilesDir}/${themeSources.light}"
            else
              SOURCE_PATH="${dotfilesDir}/${themeSources.dark}"
            fi
            mkdir -p "$(dirname "$TARGET_PATH")"
            if [ "$(readlink "$TARGET_PATH")" != "$SOURCE_PATH" ]; then
              echo "Linking $TARGET_PATH -> $SOURCE_PATH"
              ln -sf "$SOURCE_PATH" "$TARGET_PATH"
            fi
          '') cfg.themedMappings
        )}
        # Optional: Run custom script hook in repo if present
        if [ -x "${dotfilesDir}/scripts/theme-switcher.sh" ]; then
          "${dotfilesDir}/scripts/theme-switcher.sh" "$MODE"
        fi
      '';
    in
    {
      options.services.dotfiles = {
        enable = lib.mkEnableOption "Custom Dotfiles Management";
        user = lib.mkOption {
          type = lib.types.str;
          description = "The username who owns the dotfiles.";
        };
        repo = lib.mkOption {
          type = lib.types.str;
          example = "https://github.com/username/dotfiles.git";
          description = "The GitHub repository URL to clone.";
        };
        defaultTheme = lib.mkOption {
          type = lib.types.enum [
            "dark"
            "light"
          ];
          default = "dark";
          description = "Default theme mode to apply on initial activation if no saved state exists.";
        };
        mappings = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            ".config/alacritty" = "alacritty";
            ".config/i3" = "i3";
            ".zshrc" = "zsh/.zshrc";
          };
          description = ''
            An attribute set mapping target paths (relative to home) 
            to source paths (relative to the dotfiles repo root).
          '';
        };
        themedMappings = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                dark = lib.mkOption {
                  type = lib.types.str;
                  description = "Source path (relative to dotfiles repo root) for dark mode.";
                };
                light = lib.mkOption {
                  type = lib.types.str;
                  description = "Source path (relative to dotfiles repo root) for light mode.";
                };
              };
            }
          );
          default = { };
          example = {
            ".config/alacritty/colors.toml" = {
              dark = "alacritty/rose-pine.toml";
              light = "alacritty/rose-pine-dawn.toml";
            };
          };
          description = ''
            An attribute set mapping target paths (relative to home)
            to dark and light source paths (relative to dotfiles repo root).
          '';
        };
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.git
          themeSwitcher
        ];
        environment.shellInit = ''
          if [ -d "${dotfilesDir}/scripts" ]; then
            export PATH="$PATH:${dotfilesDir}/scripts"
          fi
        '';
        system.activationScripts.dotfilesSync = {
          deps = [ "users" ];
          text = ''
            echo "Syncing dotfiles for ${cfg.user}..."
            # 1. Clone repo if missing
            if [ ! -d "${dotfilesDir}" ]; then
              echo "Cloning repo to ${dotfilesDir}..."
              ${pkgs.git}/bin/git clone "${cfg.repo}" "${dotfilesDir}"
              chown -R ${cfg.user}:${user.group} "${dotfilesDir}"
            fi
            # 2. Make repo theme-switcher script executable if present
            if [ -f "${dotfilesDir}/scripts/theme-switcher.sh" ]; then
              chmod +x "${dotfilesDir}/scripts/theme-switcher.sh"
              chown ${cfg.user}:${user.group} "${dotfilesDir}/scripts/theme-switcher.sh"
            fi
            # 3. Process static mappings
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (target: source: ''
                TARGET_PATH="${homeDir}/${target}"
                SOURCE_PATH="${dotfilesDir}/${source}"
                mkdir -p "$(dirname "$TARGET_PATH")"
                chown ${cfg.user}:${user.group} "$(dirname "$TARGET_PATH")"
                if [ "$(readlink "$TARGET_PATH")" != "$SOURCE_PATH" ]; then
                  echo "Linking $TARGET_PATH -> $SOURCE_PATH"
                  if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                    mv "$TARGET_PATH" "$TARGET_PATH.bak"
                  fi
                  ln -sf "$SOURCE_PATH" "$TARGET_PATH"
                  chown -h ${cfg.user}:${user.group} "$TARGET_PATH"
                fi
              '') cfg.mappings
            )}
            # 4. Process themed mappings based on saved or default mode
            THEME_STATE_FILE="${homeDir}/.config/theme_mode"
            mkdir -p "${homeDir}/.config"
            chown ${cfg.user}:${user.group} "${homeDir}/.config"
            CURRENT_THEME="${cfg.defaultTheme}"
            if [ -f "$THEME_STATE_FILE" ]; then
              SAVED_THEME="$(cat "$THEME_STATE_FILE" | tr -d ' \n\r')"
              if [ "$SAVED_THEME" = "dark" ] || [ "$SAVED_THEME" = "light" ]; then
                CURRENT_THEME="$SAVED_THEME"
              fi
            else
              echo "$CURRENT_THEME" > "$THEME_STATE_FILE"
              chown ${cfg.user}:${user.group} "$THEME_STATE_FILE"
            fi
            echo "Applying $CURRENT_THEME theme mappings for ${cfg.user}..."
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (target: themeSources: ''
                TARGET_PATH="${homeDir}/${target}"
                if [ "$CURRENT_THEME" = "light" ]; then
                  SOURCE_PATH="${dotfilesDir}/${themeSources.light}"
                else
                  SOURCE_PATH="${dotfilesDir}/${themeSources.dark}"
                fi
                mkdir -p "$(dirname "$TARGET_PATH")"
                chown ${cfg.user}:${user.group} "$(dirname "$TARGET_PATH")"
                if [ "$(readlink "$TARGET_PATH")" != "$SOURCE_PATH" ]; then
                  echo "Linking $TARGET_PATH -> $SOURCE_PATH ($CURRENT_THEME mode)"
                  if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                    mv "$TARGET_PATH" "$TARGET_PATH.bak"
                  fi
                  ln -sf "$SOURCE_PATH" "$TARGET_PATH"
                  chown -h ${cfg.user}:${user.group} "$TARGET_PATH"
                fi
              '') cfg.themedMappings
            )}
          '';
        };
      };
    };
}

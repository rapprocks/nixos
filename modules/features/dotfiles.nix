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
      # Generated user command: theme-switcher [dark|light|toggle]
      # Operates on the invoking user's $HOME, so it works for every synced user.
      themeSwitcher = pkgs.writeShellScriptBin "theme-switcher" ''
        THEME_STATE_FILE="$HOME/.config/theme_mode"
        DOTFILES_DIR="$HOME/.dotfiles"
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
            TARGET_PATH="$HOME/${target}"
            if [ "$MODE" = "light" ]; then
              SOURCE_PATH="$DOTFILES_DIR/${themeSources.light}"
            else
              SOURCE_PATH="$DOTFILES_DIR/${themeSources.dark}"
            fi
            mkdir -p "$(dirname "$TARGET_PATH")"
            if [ "$(readlink "$TARGET_PATH")" != "$SOURCE_PATH" ]; then
              echo "Linking $TARGET_PATH -> $SOURCE_PATH"
              ln -sf "$SOURCE_PATH" "$TARGET_PATH"
            fi
          '') cfg.themedMappings
        )}
        # Optional: Run custom script hook in repo if present
        if [ -x "$DOTFILES_DIR/scripts/theme-switcher.sh" ]; then
          "$DOTFILES_DIR/scripts/theme-switcher.sh" "$MODE"
        fi
      '';

      # Per-user activation snippet. Links shared + host-specific mappings
      # (cfg.mappings) plus this user's own mappings, from the user's own clone.
      syncForUser = u: userCfg: ''
        if id "${u}" >/dev/null 2>&1; then
          U_HOME="$(getent passwd "${u}" | cut -d: -f6)"
          U_GROUP="$(id -gn "${u}")"
          U_DOTFILES="$U_HOME/.dotfiles"

          echo "Syncing dotfiles for ${u} ($U_HOME)..."

          # 1. Clone repo if missing
          if [ ! -d "$U_DOTFILES" ]; then
            echo "Cloning repo to $U_DOTFILES..."
            ${pkgs.git}/bin/git clone "${cfg.repo}" "$U_DOTFILES"
            chown -R "${u}:$U_GROUP" "$U_DOTFILES"
          fi

          # 2. Make repo theme-switcher script executable if present
          if [ -f "$U_DOTFILES/scripts/theme-switcher.sh" ]; then
            chmod +x "$U_DOTFILES/scripts/theme-switcher.sh"
            chown "${u}:$U_GROUP" "$U_DOTFILES/scripts/theme-switcher.sh"
          fi

          # 3. Process static mappings
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (target: source: ''
              TARGET_PATH="$U_HOME/${target}"
              SOURCE_PATH="$U_DOTFILES/${source}"
              mkdir -p "$(dirname "$TARGET_PATH")"
              chown "${u}:$U_GROUP" "$(dirname "$TARGET_PATH")"
              if [ "$(readlink "$TARGET_PATH")" != "$SOURCE_PATH" ]; then
                echo "Linking $TARGET_PATH -> $SOURCE_PATH"
                if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                  mv "$TARGET_PATH" "$TARGET_PATH.bak"
                fi
                ln -sf "$SOURCE_PATH" "$TARGET_PATH"
                chown -h "${u}:$U_GROUP" "$TARGET_PATH"
              fi
            '') (cfg.mappings // userCfg.mappings)
          )}

          # 4. Process themed mappings based on saved or default mode
          THEME_STATE_FILE="$U_HOME/.config/theme_mode"
          mkdir -p "$U_HOME/.config"
          chown "${u}:$U_GROUP" "$U_HOME/.config"
          CURRENT_THEME="${cfg.defaultTheme}"
          if [ -f "$THEME_STATE_FILE" ]; then
            SAVED_THEME="$(cat "$THEME_STATE_FILE" | tr -d ' \n\r')"
            if [ "$SAVED_THEME" = "dark" ] || [ "$SAVED_THEME" = "light" ]; then
              CURRENT_THEME="$SAVED_THEME"
            fi
          else
            echo "$CURRENT_THEME" > "$THEME_STATE_FILE"
            chown "${u}:$U_GROUP" "$THEME_STATE_FILE"
          fi
          echo "Applying $CURRENT_THEME theme mappings for ${u}..."
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (target: themeSources: ''
              TARGET_PATH="$U_HOME/${target}"
              if [ "$CURRENT_THEME" = "light" ]; then
                SOURCE_PATH="$U_DOTFILES/${themeSources.light}"
              else
                SOURCE_PATH="$U_DOTFILES/${themeSources.dark}"
              fi
              mkdir -p "$(dirname "$TARGET_PATH")"
              chown "${u}:$U_GROUP" "$(dirname "$TARGET_PATH")"
              if [ "$(readlink "$TARGET_PATH")" != "$SOURCE_PATH" ]; then
                echo "Linking $TARGET_PATH -> $SOURCE_PATH ($CURRENT_THEME mode)"
                if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
                  mv "$TARGET_PATH" "$TARGET_PATH.bak"
                fi
                ln -sf "$SOURCE_PATH" "$TARGET_PATH"
                chown -h "${u}:$U_GROUP" "$TARGET_PATH"
              fi
            '') cfg.themedMappings
          )}
        fi
      '';
    in
    {
      options.services.dotfiles = {
        enable = lib.mkEnableOption "Custom Dotfiles Management";
        users = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.mappings = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "User-specific mappings, linked only for this user.";
              };
            }
          );
          default = { };
          description = ''
            Users whose dotfiles are synced, keyed by username. Each user module
            (modules/users/*.nix) declares its own entry and user-specific mappings.
          '';
        };
        repo = lib.mkOption {
          type = lib.types.str;
          example = "https://github.com/username/dotfiles.git";
          description = "The GitHub repository URL to clone into each user's ~/.dotfiles.";
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
        services.dotfiles = {
          mappings = {
            ".config/niri/config.kdl" = "niri/2027.kdl";
            ".config/kanshi/config" = "kanshi/config";
            ".config/alacritty/alacritty.toml" = "alacritty/alacritty.toml";
            ".config/fuzzel/fuzzel.ini" = "fuzzel/fuzzel.ini";
            ".config/rofi/config.rasi" = "rofi/rose-pine.rasi";
            ".config/swayosd/config.toml" = "swayosd/config.toml";
            ".config/swayosd/style.css" = "swayosd/style.css";
            ".config/tmux/tmux.conf" = "tmux/tmux.conf";
            ".config/tmux/dotbar.tmux" = "tmux/dotbar.tmux";
            ".config/rbw/config.json" = "rbw/config.json";
            ".config/opencode/themes" = "opencode/themes";
            ".config/opencode/skills" = "opencode/skills";
            ".config/opencode/opencode.json" = "opencode/opencode.json";
            ".config/yazi/yazi.toml" = "yazi/yazi.toml";
            ".config/yazi/flavors" = "yazi/flavors";
            ".config/yazi/theme.toml" = "yazi/theme.toml";
            ".config/waybar/config.jsonc" = "waybar/2027.jsonc";
            ".config/waybar/style.css" = "waybar/2027.css";
            ".config/herdr/config.toml" = "herdr/config.toml";
            ".gitconfig" = ".gitconfig";
            ".config/hypr/hypridle.conf" = "hypr/hypridle.conf";
            ".config/hypr/hyprlock.conf" = "hypr/hyprlock.conf";
            ".pi/agent/settings.json" = "pi/agent/settings.json";
            ".pi/agent/mcp.json" = "pi/agent/mcp.json";
            ".pi/agent/models.json" = "pi/agent/models.json";
            ".pi/agent/extensions" = "pi/agent/extensions";
            ".pi/agent/themes" = "pi/agent/themes";
          };
          themedMappings = {
            ".config/alacritty/colors.toml" = {
              dark = "alacritty/rose-pine.toml";
              light = "alacritty/rose-pine-dawn.toml";
            };
            ".config/fuzzel/colors.ini" = {
              dark = "fuzzel/rose-pine.ini";
              light = "fuzzel/rose-pine-dawn.ini";
            };
            ".config/tmux/colors.conf" = {
              dark = "tmux/rose-pine.conf";
              light = "tmux/rose-pine-dawn.conf";
            };
            ".config/swaync/style.css" = {
              dark = "swaync/rose-pine.css";
              light = "swaync/rose-pine-dawn.css";
            };
            ".config/waybar/colors.css" = {
              dark = "waybar/rose-pine.css";
              light = "waybar/rose-pine-dawn.css";
            };
          };
        };

        environment.systemPackages = [
          pkgs.git
          themeSwitcher
        ];
        environment.shellInit = ''
          if [ -d "$HOME/.dotfiles/scripts" ]; then
            export PATH="$PATH:$HOME/.dotfiles/scripts"
          fi
        '';
        system.activationScripts.dotfilesSync = {
          deps = [ "users" ];
          text = lib.concatStringsSep "\n" (lib.mapAttrsToList syncForUser cfg.users);
        };
      };
    };
}

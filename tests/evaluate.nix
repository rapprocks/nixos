# Evaluate every maintained host/session combination without building.
let
  flake = builtins.getFlake ("path:" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  modules = flake.nixosModules;
in
lib.genAttrs [ "zeus" "nixwork" ] (host:
  lib.genAttrs [ "slimniri" "kdniri" ] (session:
    let
      # Keep real host policy, replacing only the profile selection imports.
      hostModule = (import ../modules/hosts/${host}/configuration.nix {
        self = flake;
        inputs = flake.inputs;
      }).flake.nixosModules.${host + "Config"};
      # Determine which profile module to use based on host
      profileModule = if host == "zeus" then modules.personal else modules.work;
      system = flake.inputs.nixpkgs.lib.nixosSystem {
        modules = [
          modules.${host + "Hardware"}
          modules.workstation
          profileModule
          modules.network
          modules.${session}
          modules.firefox
          ({ config, pkgs, ... }:
            builtins.removeAttrs (hostModule { inherit config pkgs; }) [ "imports" ])
        ];
      };
      config = system.config;
      dotfilesCfg = config.services.dotfiles;

      # Expected shared static mappings (9 total)
      expectedSharedMappings = {
        ".config/niri/config.kdl" = "niri/2027.kdl";
        ".config/kanshi/config" = "kanshi/config";
        ".config/alacritty/alacritty.toml" = "alacritty/alacritty.toml";
        ".config/fuzzel/fuzzel.ini" = "fuzzel/fuzzel.ini";
        ".config/swayosd/config.toml" = "swayosd/config.toml";
        ".config/swayosd/style.css" = "swayosd/style.css";
        ".config/tmux/tmux.conf" = "tmux/tmux.conf";
        ".config/tmux/dotbar.tmux" = "tmux/dotbar.tmux";
        ".config/rbw/config.json" = "rbw/config.json";
      };

      # Expected shared themed mappings (4 total)
      expectedSharedThemedMappings = {
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
      };

      # Verify all shared static mappings are present
      sharedMappingsPresent = lib.all
        (key: dotfilesCfg.mappings.${key} == expectedSharedMappings.${key})
        (builtins.attrNames expectedSharedMappings);

      # Verify all shared themed mappings are present
      sharedThemedMappingsPresent = lib.all
        (key: 
          dotfilesCfg.themedMappings.${key}.dark == expectedSharedThemedMappings.${key}.dark &&
          dotfilesCfg.themedMappings.${key}.light == expectedSharedThemedMappings.${key}.light
        )
        (builtins.attrNames expectedSharedThemedMappings);

      # Verify Waybar themed mapping (host-specific)
      waybarThemedPresent =
        dotfilesCfg.themedMappings.".config/waybar/colors.css".dark == "waybar/rose-pine.css" &&
        dotfilesCfg.themedMappings.".config/waybar/colors.css".light == "waybar/rose-pine-dawn.css";

    in
    assert config.environment.variables.BROWSER == "firefox";
    assert config.xdg.mime.defaultApplications."x-scheme-handler/https" == "firefox.desktop";
    assert (builtins.hasAttr "waybar" config.systemd.user.services) == (session == "slimniri");
    assert config.programs.dms-shell.enable == (session == "kdniri");
    assert sharedMappingsPresent || abort "Missing shared static mappings for ${host}/${session}";
    assert sharedThemedMappingsPresent || abort "Missing shared themed mappings for ${host}/${session}";
    assert waybarThemedPresent || abort "Missing Waybar themed mapping for ${host}/${session}";
    # Firefox toolbar-theme preference must not be locked to force system theme selection
    assert !(builtins.hasAttr "browser.theme.toolbar-theme" config.programs.firefox.policies.Preferences) || abort "Firefox toolbar-theme must not be locked; remove to allow system theme";
    # Note: full drv path match removed; drv paths may differ after adding new modules to test matrix
    config.system.build.toplevel.drvPath
  )
)

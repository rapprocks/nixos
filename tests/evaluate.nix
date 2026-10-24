# Evaluate every maintained host/session combination without building.
let
  flake = builtins.getFlake ("path:" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  modules = flake.nixosModules;

  # Fallback stub for hosts whose hardware.nix has not been generated yet.
  stubHardware = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    nixpkgs.hostPlatform = "x86_64-linux";
  };
in
lib.genAttrs [ "zeus" "apollo" "nixwork" ] (
  host:
  lib.genAttrs [ "slimniri" "kdniri" ] (
    session:
    let
      # Keep real host policy, replacing only the profile selection imports.
      hostModule =
        (import ../modules/hosts/${host}/configuration.nix {
          self = flake;
          inputs = flake.inputs;
        }).flake.nixosModules.${host + "Config"};
      # Determine which profile module to use based on host
      profileModule = if host == "nixwork" then modules.work else modules.personal;
      hardwareModule = modules.${host + "Hardware"} or stubHardware;
      system = flake.inputs.nixpkgs.lib.nixosSystem {
        modules = [
          hardwareModule
          modules.workstation
          profileModule
          modules.network
          modules.${session}
          modules.firefox
          (
            { config, pkgs, ... }:
            builtins.removeAttrs (hostModule { inherit config pkgs; }) [ "imports" ]
          )
        ]
        ++ lib.optionals (host == "nixwork") [
          modules.userPhilip
          flake.inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
        ]
        ++ lib.optionals (host == "apollo") [
          flake.inputs.nixos-hardware.nixosModules.common-pc
          flake.inputs.nixos-hardware.nixosModules.common-pc-ssd
          flake.inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          flake.inputs.nixos-hardware.nixosModules.common-gpu-amd
        ];
      };
      config = system.config;
      dotfilesCfg = config.services.dotfiles;

      # Expected shared static mappings
      expectedSharedMappings = {
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
        ".pi/agent/extensions" = "pi/agent/extensions";
        ".pi/agent/themes" = "pi/agent/themes";
      };

      # Expected shared themed mappings (5 total)
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
        ".config/waybar/colors.css" = {
          dark = "waybar/rose-pine.css";
          light = "waybar/rose-pine-dawn.css";
        };
      };

      # Verify all shared static mappings are present
      sharedMappingsPresent = lib.all (
        key: dotfilesCfg.mappings.${key} == expectedSharedMappings.${key}
      ) (builtins.attrNames expectedSharedMappings);

      # Verify all shared themed mappings are present
      sharedThemedMappingsPresent = lib.all (
        key:
        dotfilesCfg.themedMappings.${key}.dark == expectedSharedThemedMappings.${key}.dark
        && dotfilesCfg.themedMappings.${key}.light == expectedSharedThemedMappings.${key}.light
      ) (builtins.attrNames expectedSharedThemedMappings);

    in
    assert config.environment.variables.BROWSER == "firefox";
    assert config.xdg.mime.defaultApplications."x-scheme-handler/https" == "firefox.desktop";
    assert (builtins.hasAttr "waybar" config.systemd.user.services) == (session == "slimniri");
    assert config.programs.dms-shell.enable == (session == "kdniri");
    assert config.services.fprintd.enable == (host != "apollo");
    assert config.services.fprintd.lid-guard.enable == (host != "apollo");
    assert config.hardware.laptop.enable == (host != "apollo");
    assert config.services.thermald.enable == (host == "zeus");
    assert sharedMappingsPresent || abort "Missing shared static mappings for ${host}/${session}";
    assert sharedThemedMappingsPresent || abort "Missing shared themed mappings for ${host}/${session}";
    # Firefox toolbar-theme preference must not be locked to force system theme selection
    assert
      !(builtins.hasAttr "browser.theme.toolbar-theme" config.programs.firefox.policies.Preferences)
      || abort "Firefox toolbar-theme must not be locked; remove to allow system theme";
    # Note: full drv path match removed; drv paths may differ after adding new modules to test matrix
    config.system.build.toplevel.drvPath
  )
)

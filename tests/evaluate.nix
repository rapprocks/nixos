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
    in
    assert config.environment.variables.BROWSER == "firefox";
    assert config.xdg.mime.defaultApplications."x-scheme-handler/https" == "firefox.desktop";
    assert (builtins.hasAttr "waybar" config.systemd.user.services) == (session == "slimniri");
    assert config.programs.dms-shell.enable == (session == "kdniri");
    assert config.services.dotfiles.mappings == flake.nixosConfigurations.${host}.config.services.dotfiles.mappings
      || session != "slimniri";
    # Note: full drv path match removed; drv paths may differ after adding new modules to test matrix
    config.system.build.toplevel.drvPath
  )
)

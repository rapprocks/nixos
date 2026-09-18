# Evaluate every maintained host/session/browser combination without building.
let
  flake = builtins.getFlake ("path:" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  modules = flake.nixosModules;
in
lib.genAttrs [ "kde" "zeus" ] (host:
  lib.genAttrs [ "slimniri" "kdniri" ] (session:
    lib.genAttrs [ "firefox" "librewolf" ] (browser:
      let
        # Keep real host policy, replacing only the profile selection imports.
        hostModule = (import ../modules/hosts/${host}/configuration.nix {
          self = flake;
          inputs = flake.inputs;
        }).flake.nixosModules.${host + "Config"};
        system = flake.inputs.nixpkgs.lib.nixosSystem {
          modules = [
            modules.${host + "Hardware"}
            modules.workstation
            modules.${session}
            modules.${browser}
            modules.nasMounts
            ({ config, pkgs, ... }:
              builtins.removeAttrs (hostModule { inherit config pkgs; }) [ "imports" ])
          ];
        };
        config = system.config;
      in
      assert config.environment.variables.BROWSER == browser;
      assert config.xdg.mime.defaultApplications."x-scheme-handler/https" == "${browser}.desktop";
      assert (builtins.hasAttr "waybar" config.systemd.user.services) == (session == "slimniri");
      assert config.programs.dms-shell.enable == (session == "kdniri");
      assert config.services.dotfiles.mappings == flake.nixosConfigurations.${host}.config.services.dotfiles.mappings
        || session != "slimniri";
      assert session != "slimniri" || browser != "firefox"
        || config.system.build.toplevel.drvPath == flake.nixosConfigurations.${host}.config.system.build.toplevel.drvPath;
      config.system.build.toplevel.drvPath
    )
  )
)

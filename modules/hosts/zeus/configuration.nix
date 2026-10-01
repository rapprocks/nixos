{ self, inputs, ... }: {
  flake.nixosConfigurations.zeus = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.zeusConfig ];
  };

  flake.nixosModules.zeusConfig = { pkgs, config, ... }: {
    imports = [
      self.nixosModules.zeusHardware
      self.nixosModules.workstation
      self.nixosModules.personal
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
    ];

    environment.systemPackages = with pkgs; [
      blender
      orca-slicer
      gimp
      freecad

    ];

    services.fprintd.enable = true;

    # only try fingerprint reader if the lid is open
    security.pam.services.hyprlock.rules.auth = {
      fprintd-only-if-lid-open = {
        enable = true;
        order = config.security.pam.services.hyprlock.rules.auth.fprintd.order - 1; # go immediately before fprintd
        control = "[success=ok default=1]";
        modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
        args = [
          "quiet"
          "quiet_log"
          "${pkgs.writeShellScript "is-lid-open" ''
            # this script exits with exit code 1 if anything goes wrong or the lid is closed; returns 0 if lid is open

            set -eoui pipefail
            lidstate="$(${config.systemd.package}/bin/busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed 2>/dev/null)"

            if [ "''${lidstate}" = "b false" ]; then
              exit 0
            fi

            exit 1

          ''}"
        ];
      };
    };

    networking.hostName = "zeus";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."nixos".device = "/dev/disk/by-uuid/0a6f4373-9f5f-4e40-bea3-e953009834c3";

    # Machine-specific graphics and power policy.
    boot.initrd.kernelModules = [ "i915" ];
    boot.kernelParams = [ "i915.force_probe=a7a1" ];
    hardware.graphics.extraPackages = [ pkgs.vpl-gpu-rt ];
    services.power-profiles-daemon.enable = true;
    services.thermald.enable = true;
    powerManagement.powertop.enable = false;

    services.dm.greetd = {
      enable = true;
      autoLogin = true;
    };

    # Enable Wi-Fi and Syncthing for this personal host
    networking.enabledWifiNetworks = [ "k69" ];
    services.syncthingSync = {
      enable = true;
      folders = {
        "notes" = {
          id = "notes";
          path = "/home/earn/Documents/notes";
          devices = [
            "zeus"
            "truenas"
          ];
        };
        "wallpapers" = {
          id = "wallpapers";
          path = "/home/earn/Pictures/wallpapers";
          devices = [
            "zeus"
            "truenas"
            "nixwork"
          ];
        };
      };
    };

    services.desktopApps."feedly" = {
      enable = true;
      sourcePath = "~/.dotfiles/apps/feedly.desktop";
      iconPath = "~/.dotfiles/apps/icons/feedly.png";
    };

    services.desktopApps."x" = {
      enable = true;
      sourcePath = "~/.dotfiles/apps/x.desktop";
      iconPath = "~/.dotfiles/apps/icons/x.png";
    };

    # Additions specific to this host; shared mappings live with their features.
    services.dotfiles = {
      mappings = {
        ".config/waybar/config.jsonc" = "waybar/2027.jsonc";
        ".config/waybar/style.css" = "waybar/2027.css";
        ".config/waybar/group-center.jsonc" = "waybar/group-center.jsonc";
        ".config/herdr/config.toml" = "herdr/config.toml";
        ".config/opencode/themes" = "opencode/themes";
        ".gitconfig" = ".gitconfig";

        ".config/hypr/hypridle.conf" = "hypr/hypridle.conf";
        ".config/hypr/hyprlock.conf" = "hypr/hyprlock.conf";
      };
      themedMappings.".config/waybar/colors.css" = {
        dark = "waybar/rose-pine.css";
        light = "waybar/rose-pine-dawn.css";
      };
    };
  };
}

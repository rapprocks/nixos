{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.nixwork = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.nixworkConfig ];
  };

  flake.nixosModules.nixworkConfig = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.nixworkHardware
      self.nixosModules.workstation
      self.nixosModules.userPhilip
      self.nixosModules.work
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ];

    preferences = {
      host.name = "nixwork";
      user.name = "earn";
      user.extraUsers = [ "philip" ];
    };

    sops.secrets.librenms_api_token = {
      owner = config.preferences.user.name;
      group = "keys";
      mode = "0440";
    };

    environment.systemPackages = with pkgs; [
      ngrok
      amdtop
    ];

    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."luks-e23c56ef-712d-4c70-9b40-525e09217a72".device =
      "/dev/disk/by-uuid/e23c56ef-712d-4c70-9b40-525e09217a72";

    hardware.laptop.enable = true;

    ### Custom NixOS options ###

    services.desktopApps = {
      "google-chat" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/google-chat.desktop";
        iconPath = "~/.dotfiles/apps/icons/google-chat.png";
      };
      "google-gemini" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/gemini.desktop";
        iconPath = "~/.dotfiles/apps/icons/google-gemini.png";
      };
      "spotify" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/spotify.desktop";
        iconPath = "~/.dotfiles/apps/icons/spotify.png";
      };
      "theme" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/theme.desktop";
        iconPath = "~/.dotfiles/apps/icons/theme.png";
      };
      "bluetui" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/bluetui.desktop";
        iconPath = "~/.dotfiles/apps/icons/bluetui.png";
      };
      "librenms" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/libre.desktop";
        iconPath = "~/.dotfiles/apps/icons/librenms.png";
      };
      "wireguard" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/wg-work.desktop";
        iconPath = "~/.dotfiles/apps/icons/wireguard.png";
      };
    };

    # Enable Wi-Fi and Syncthing for this work host
    networking.enabledWifiNetworks = [
      "k69"
      "work"
    ];

    services.virtualisation.enable = true;
    services.docker.enable = true;
    # Multiple users on this host: no auto-login, greetd shows the login prompt.
    services.dm.greetd = {
      enable = true;
      autoLogin = false;
    };

    services.agentic = {
      enable = true;
      acceleration = "vulkan"; # Radeon 890M iGPU via Mesa RADV
      models = {
        "qwen2.5-coder-14b" = "unsloth/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M";
        "deepseek-r1-8b" = "unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M";
      };
    };

    services.syncthingSync = {
      enable = true;
      folders = {
        "wallpapers" = {
          id = "wallpapers";
          path = "~/Pictures/wallpapers";
          devices = [
            "apollo"
            "zeus"
            "nixwork"
          ];
        };
      };
    };
  };
}

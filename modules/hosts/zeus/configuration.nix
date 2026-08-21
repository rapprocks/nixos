{ self, inputs, ... }: {
  flake.nixosConfigurations.zeus = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.zeusConfig
    ];
  };
  flake.nixosModules.zeusConfig = { pkgs, ... }: {
    imports = [
      #self.nixosModules.zeusHardware
      self.nixosModules.common
      #self.nixosModules.kdeniri
      self.nixosModules.slimniri
      self.nixosModules.nasMounts
      ./hardware-configuration.nix
    ];

    ## ADDED BY ME ##
    services.dotfiles = {
      enable = true;
      user = "earn";
      repo = "https://github.com/rapprocks/dotfiles.git";
      mappings = {
        ".config/niri/config.kdl" = "niri/2027.kdl";
        ".config/kanshi/config" = "kanshi/config";
        ".config/alacritty/alacritty.toml" = "alacritty/alacritty.toml";
        ".config/fuzzel/fuzzel.ini" = "fuzzel/fuzzel.ini";
        ".config/tmux/tmux.conf" = "tmux/tmux.conf";
        ".config/tmux/dotbar.tmux" = "tmux/dotbar.tmux";
        ".config/swaync/config.json" = "swaync/config.json";
        ".config/rbw/config.json" = "rbw/config.json";
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
      };
    };

    fonts = {
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
    };

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    services.openssh.enable = true;

    ############################################################

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "zeus"; # Define your hostname.
    # Enable networking
    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
      wget
      tldr
      git
      fastfetch
      libnotify
      inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  };
}

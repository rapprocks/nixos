{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../hyprland.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = ["i915.force_probe=a7a1"];
  boot.initrd.kernelModules = ["i915"];

  networking.hostName = "nix"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [pkgs.vpl-gpu-rt];
  };

  services = {
    gnome.gcr-ssh-agent.enable = false;
    pcscd.enable = true;
    logind = {
      settings = {
        Login = {
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "lock";
        };
      };
    };
    fstrim.enable = true;
    upower.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      # Enable WirePlumber for session management
      wireplumber.enable = true;
    };
    # Disable power-profiles-daemon (pulled in by COSMIC) in favor of auto-cpufreq
    power-profiles-daemon.enable = false;
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "auto";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
    gnome.gnome-keyring.enable = true;
    displayManager.ly = {
      enable = true;
      settings = {
        bg = "0xFF000000";
      };
    };
    desktopManager = {
      cosmic = {
        enable = true;
        xwayland.enable = true;
      };
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
    ];
    config = {
      hyprland = {
        "org.freedesktop.impl.portal.FileChooser" = "cosmic-files";
        "org.freedesktop.impl.portal.ScreenCast" = ["gtk" "hyprland"];
        "org.freedesktop.impl.portal.Screenshot" = "gtk";
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security = {
    polkit.enable = true;
    tpm2.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.philip = {
    isNormalUser = true;
    description = "philip";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
    ];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "philip";

  environment.systemPackages = with pkgs; [
    helix
    code-cursor
    wget
    curl
    git
    eza
    fzf
    tmux
    alacritty
    firefox
    chromium
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    xdg-utils
    nwg-look
    adwaita-icon-theme
    kanshi
    remmina
    cameractrls-gtk4
    swayosd
    libnotify
    mako
    pavucontrol # PulseAudio Volume Control
    pamixer # Command-line mixer for PulseAudio
    bluez # Bluetooth support
    bluez-tools # Bluetooth tools
    bluetuith
    wl-clipboard
    brightnessctl
    fuzzel
    waybar
    nixd
    yazi
    bat
    tldr
    jq
    zoxide
    ripgrep
    typescript
    nodejs
    signal-desktop
    obsidian
    gnome-calculator
    inputs.nixvim.packages.${pkgs.system}.default
  ];

  fonts = {
    fontDir.enable = true;
    fontconfig.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      font-awesome_5
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Noto Sans"];
        monospace = ["JetBrainsMono Nerd Font Mono"];
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    enableLsColors = true;
    ohMyZsh.enable = true;
    ohMyZsh.plugins = [
      "colored-man-pages"
    ];
    shellInit = ''
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
    shellAliases = {
      ip = "ip --color";
      cp = "rsync -ah --progress";
      dot = "cd ~/.dotfiles";
      dev = "cd ~/Development";
      tree = "tree -C";
      weather = "curl -S 'https://wttr.in/Stockholm?1F'";
      cat = "bat --style plain";
      ga = "git add";
      gst = "git status";
      gcm = "git commit -m";
      gpum = "git push -u origin main";
      ta = "tmux attach";
      vim = "nvim";
      vi = "nvim";
      nsp = "nix-shell -p";
      rb = "sudo nixos-rebuild switch --flake ~/.dotfiles#";
      conf = "~/.config";
      # eza
      ls = "eza --group-directories-first";
      ll = "eza -l --group-directories-first";
      la = "eza -a --group-directories-first";
      lt = "eza --tree --group-directories-first";
      lla = "eza -la --group-directories-first";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  systemd.user.services.kanshi = {
    enable = true;
    description = "Kanshi monitor service";
    bindsTo = ["graphical-session.target"];
    #wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  networking.firewall.enable = false;

  nix = {
    settings = {
      trusted-users = [
        "root"
        "philip"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05"; # Did you read the comment?
  system.autoUpgrade = {
    enable = true;
    flake = "/home/philip/.dotfiles#nixlab";
    flags = [
      "--update-input"
      "nixpkgs"
    ];
  };
}

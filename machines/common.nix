{
  pkgs,
  inputs,
  username,
  ...
}: {
  # ──────────────────────────────────────────────────────────────
  # LOCALE & TIME
  # ──────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb = {
    layout = "se";
    variant = "nodeadkeys";
  };
  console.keyMap = "sv-latin1";

  # ──────────────────────────────────────────────────────────────
  # BOOT
  # ──────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ──────────────────────────────────────────────────────────────
  # NETWORKING
  # ──────────────────────────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  networking.firewall.enable = true;

  # ──────────────────────────────────────────────────────────────
  # HARDWARE (shared)
  # ──────────────────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ──────────────────────────────────────────────────────────────
  # SERVICES
  # ──────────────────────────────────────────────────────────────
  services = {
    tailscale.enable = true;
    gnome.gcr-ssh-agent.enable = false;
    fstrim.enable = true;
    upower.enable = true;
    gnome.gnome-keyring.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      wireplumber.enable = true;
    };

    displayManager.ly = {
      enable = true;
      settings = {
        auto_login_service = "ly-autologin";
        auto_login_session = "Hyprland";
        auto_login_user = username;
        box_title = "whatsup my man";
      };
    };

    desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = username;
      dataDir = "/home/${username}";
    };
  };

  # ──────────────────────────────────────────────────────────────
  # XDG PORTALS
  # ──────────────────────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
    ];
    config.hyprland = {
      "org.freedesktop.impl.portal.FileChooser" = "cosmic-files";
      "org.freedesktop.impl.portal.ScreenCast" = ["gtk" "hyprland"];
      "org.freedesktop.impl.portal.Screenshot" = "gtk";
    };
  };

  # ──────────────────────────────────────────────────────────────
  # CORE SECURITY
  # ──────────────────────────────────────────────────────────────
  security.polkit.enable = true;
  security.tpm2.enable = true;
  programs.ssh.startAgent = true;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # ──────────────────────────────────────────────────────────────
  # USER (shared definition)
  # ──────────────────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel" "input" "plugdev"];
  };

  # ──────────────────────────────────────────────────────────────
  # PACKAGES
  # ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core CLI
    wget
    curl
    git
    eza
    fzf
    tmux
    bat
    tldr
    jq
    zoxide
    ripgrep
    yazi
    htop
    btop
    fastfetch

    # Editors
    helix
    code-cursor
    inputs.nixvim.packages.${pkgs.system}.default

    # Terminals
    kitty
    alacritty

    # Browsers
    brave
    firefox
    chromium

    # Wayland/Desktop
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    xdg-utils
    nwg-look
    adwaita-icon-theme
    kanshi
    swayosd
    libnotify
    mako
    wl-clipboard
    brightnessctl
    fuzzel
    waybar
    hyprcursor

    # Media & recording
    ueberzugpp
    mpv
    feh
    slurp
    wf-recorder
    satty

    # Audio/Bluetooth
    pavucontrol
    pamixer
    bluez
    bluez-tools
    bluetuith
    bluetui

    # Apps
    signal-desktop
    obsidian
    gnome-calculator
    remmina
    cameractrls-gtk4
    bitwarden-desktop

    # Dev
    nixd
    typescript
    nodejs

    # Utils
    stow
    antigravity
    hyprshot

    # Screen recording script
    (writeShellScriptBin "screenrec" (builtins.readFile ../scripts/screenrecording.sh))
  ];

  # ──────────────────────────────────────────────────────────────
  # FONTS
  # ──────────────────────────────────────────────────────────────
  fonts = {
    fontDir.enable = true;
    fontconfig.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      font-awesome_5
    ];
    fontconfig.defaultFonts = {
      serif = ["Noto Serif"];
      sansSerif = ["Noto Sans"];
      monospace = ["JetBrainsMono Nerd Font Mono"];
    };
  };

  # ──────────────────────────────────────────────────────────────
  # SHELL (ZSH + Starship)
  # ──────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    enableLsColors = true;
    ohMyZsh = {
      enable = true;
      plugins = ["colored-man-pages"];
    };
    shellInit = ''export PATH="$HOME/.npm-global/bin:$PATH"'';
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

  # ──────────────────────────────────────────────────────────────
  # SYSTEMD SERVICES
  # ──────────────────────────────────────────────────────────────
  systemd.user.services.kanshi = {
    enable = true;
    description = "Kanshi monitor service";
    bindsTo = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
    };
  };

  # ──────────────────────────────────────────────────────────────
  # NIX SETTINGS
  # ──────────────────────────────────────────────────────────────
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs.config.allowUnfree = true;

  # ──────────────────────────────────────────────────────────────
  # DESKTOP ENVIRONMENTS
  # ──────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;
  programs.niri.enable = true;
}

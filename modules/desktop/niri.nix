{ ... }: {
  flake.nixosModules.niri = { pkgs, ... }: {
    programs.niri.enable = true;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    xdg.portal.config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    };

    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze";
    };

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      alacritty
      fuzzel
      nwg-look
      adwaita-icon-theme
      ffmpegthumbnailer
      swaybg

      satty
      nirius

      wl-clipboard
      cliphist
      kanshi
      swayosd
      swaylock-effects
      libnotify

      ## THEMING

      gsettings-desktop-schemas

      kdePackages.plasma-workspace
      kdePackages.dolphin
      kdePackages.systemsettings
      kdePackages.knewstuff

      kdePackages.breeze
      kdePackages.breeze-icons
      kdePackages.kio
      kdePackages.kio-extras
      kdePackages.plasma-integration

      #kdePackages.kde-gtk-config
      #kdePackages.qtstyleplugin-kvantum
    ];

    systemd.user.services.kanshi = {
      enable = true;
      description = "Kanshi monitor service";
      bindsTo = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kanshi}/bin/kanshi";
      };
    };

    # The shared external Niri configuration invokes swaylock and SwayOSD.
    security.pam.services.swaylock = {
      fprintAuth = true;
      u2fAuth = false;
    };

    services.dotfiles = {
      mappings = {
        ".config/niri/config.kdl" = "niri/2027.kdl";
        ".config/kanshi/config" = "kanshi/config";
        ".config/alacritty/alacritty.toml" = "alacritty/alacritty.toml";
        ".config/fuzzel/fuzzel.ini" = "fuzzel/fuzzel.ini";
        ".config/swayosd/config.toml" = "swayosd/config.toml";
        ".config/swayosd/style.css" = "swayosd/style.css";
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
      };
    };

  };
}

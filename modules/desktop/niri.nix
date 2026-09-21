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

      signal-desktop

      wireguard-tools

      satty
      nirius

      wl-clipboard
      brightnessctl
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
      kdePackages.kamoso

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
      wantedBy = [ "graphical-session.target" ]; # Adds it to the target's startup list
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kanshi}/bin/kanshi";
      };
    };
  };
}

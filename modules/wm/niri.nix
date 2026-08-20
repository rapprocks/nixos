{ ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri.enable = true;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    xdg.portal.config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    };

    environment.variables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
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
      brave # WHere should I live?
      nwg-look
      adwaita-icon-theme
      swaynotificationcenter
      ffmpegthumbnailer

      wl-clipboard
      waybar
      swayosd
      cliphist

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

    systemd.user.services.waybar = {
      description = "Waybar";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.waybar} -c /home/earn/.dotfiles/waybar/2027.jsonc -s /home/earn/.dotfiles/waybar/2027.css";
        Restart = "on-failure";
      };
      wantedBy = [ "niri.service" ];
    };

  };
}

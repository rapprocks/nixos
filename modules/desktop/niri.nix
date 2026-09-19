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
    security.pam.services.swaylock = let
      lid-guard-script = pkgs.writeShellScript "check-lid-open" ''
        # Skip fingerprint auth if lid is closed; exit success to continue to next module.
        if busctl get-property --quiet org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed | grep -q "boolean true"; then
          exit 1
        fi
        exit 0
      '';
    in {
      rules.auth = {
        lid-guard = {
          enable = true;
          order = 10; # Run before fprintd (which is at order 11400 by default)
          control = "[success=1 default=ignore]";
          modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
          args = [ "${lid-guard-script}" ];
        };
      };
      u2fAuth = false;
    };

  };
}

{ self, ... }: {
  flake.nixosModules.kdniri = { pkgs, lib, ... }: {
    imports = [ self.nixosModules.niri ];

    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
    };
    programs.dms-shell = {
      enable = true;
      enableCalendarEvents = false;
      enableAudioWavelength = false;
      enableDynamicTheming = false;
      enableSystemMonitoring = false;
    };

    security.pam.services.greetd.fprintAuth = false;

    services.displayManager.sddm.wayland.enable = false;
    services.displayManager.defaultSession = lib.mkForce "niri";

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm.enable = false;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.systemsettings
      kdePackages.knewstuff

      kdePackages.breeze
      kdePackages.breeze-icons
      kdePackages.kde-gtk-config
      kdePackages.qtstyleplugin-kvantum
    ];

    environment.etc = {
      "environment.d/10-kde-on-niri.conf".text = ''
        QT_QPA_PLATFORM=wayland
        QT_QPA_PLATFORMTHEME=kde
        QT_QPA_PLATFORMTHEME_QT6=kde
      '';
    };

  };
}

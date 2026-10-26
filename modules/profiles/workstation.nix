{ self, ... }: {
  flake.nixosModules.workstation = { pkgs, ... }: {
    imports = with self.nixosModules; [
      preferences
      system
      userEarn
      security
      pipewire
      sops
      cli
      dotfiles
      desktopApps
      displayManager
      syncthing
      virtualisation
      agentic
      fonts
      userSwitch
    ];

    services.dotfiles = {
      enable = true;
      repo = "https://github.com/rapprocks/dotfiles.git";
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.bluetooth = {
      enable = true;
      settings.General.Enable = "Source,Sink,Media,Socket";
    };

    # Shared directory
    users.groups.drop = { };
    systemd.tmpfiles.rules = [
      # Type  Path            Mode User  Group       Age Argument
      "d      /mnt/drop     2770 root  drop -   -"
    ];

    environment.systemPackages = with pkgs; [
      rbw
      rofi-rbw-wayland
      mpv
      imv
      brave
      (chromium.override { enableWideVine = true; })
      obsidian
      kdePackages.krdc
      bluetui # DECIDE WHICH ONE I WANT TO USE
      cameractrls-gtk4
      #kdePackages.bluedevil
      #kdePackages.bluez-qt
    ];

    xdg.mime.enable = true;
    xdg.mime.defaultApplications = {
      "image/jpeg" = [ "imv.desktop" ];
      "image/jpg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/mkv" = [ "mpv.desktop" ];
    };
  };
}

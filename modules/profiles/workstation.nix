{ self, ... }: {
  flake.nixosModules.workstation = { pkgs, ... }: {
    imports = with self.nixosModules; [
      system
      security
      pipewire
      sops
      cli
      dotfiles
      desktopApps
      syncthing
      virtualisation
    ];

    services.dotfiles = {
      enable = true;
      user = "earn";
      repo = "https://github.com/rapprocks/dotfiles.git";
    };

    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.bluetooth = {
      enable = true;
      settings.General.Enable = "Source,Sink,Media,Socket";
    };

    environment.systemPackages = with pkgs; [
      rbw
      rofi-rbw-wayland
      mpv
      imv
      brave
      obsidian
      kdePackages.krdc
      bluetui # DECIDE WHICH ONE I WANT TO USE
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

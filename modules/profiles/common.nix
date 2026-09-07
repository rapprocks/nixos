{ self, ... }: {
  flake.nixosModules.common = { pkgs, ... }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.security
      self.nixosModules.pipewire
      self.nixosModules.nixos
      self.nixosModules.user
      self.nixosModules.sops
      self.nixosModules.shell
      self.nixosModules.dotfiles
      self.nixosModules.firefox
      self.nixosModules.syncthing
    ];

    ## WHERE SHOULD I LIVE?
    environment.systemPackages = with pkgs; [
      kanshi
      rbw
      rofi-rbw-wayland
      mpv
      feh
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

    xdg.mime.enable = true;
    xdg.mime.defaultApplications = {
      "application/pdf" = "firefox.desktop";
      "default-web-browser" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "text/xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "image/jpeg" = [ "feh.desktop" ];
      "image/jpg" = [ "feh.desktop" ];
      "image/png" = [ "feh.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/mkv" = [ "mpv.desktop" ];
    };

    ############################################
  };
}

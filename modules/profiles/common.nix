{ self, ... }: {
  flake.nixosModules.common = { pkgs, ... }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.security
      self.nixosModules.pipewire
      self.nixosModules.nixos
      self.nixosModules.user
      self.nixosModules.shell
      self.nixosModules.dotfiles
      self.nixosModules.firefox
    ];

    ## WHERE SHOULD I LIVE?
    environment.systemPackages = with pkgs; [
      kanshi
      rbw
      rofi-rbw-wayland
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

    ############################################
  };
}

{ self, ... }: {
  flake.nixosModules.slimniri =
    { lib, pkgs, ... }:
    {
      imports = [
        self.nixosModules.niri
        self.nixosModules.displayManager
      ];

      environment.systemPackages = with pkgs; [
        waybar
        swaynotificationcenter
        kdePackages.polkit-kde-agent-1
        hyprshot
      ];

      services.hypridle.enable = true;
      programs.hyprlock.enable = true;

      services.playerctld.enable = true;

      systemd.user.services.waybar = {
        description = "Waybar";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        requisite = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.waybar}";
          Restart = "on-failure";
        };
        wantedBy = [ "niri.service" ];
      };

      systemd.user.services.polkit-kde-agent-1 = {
        description = "PolicyKit Authentication Agent";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
          BusName = "org.kde.polkit-kde-authentication-agent-1";
          Slice = "background.slice";
          Restart = "on-failure";
          TimeoutStopSec = 5;
        };
      };

      security.pam.services = {
        greetd.fprintAuth = false;
      };

    };
}

{ self, ... }: {
  flake.nixosModules.slimniri =
    { lib, pkgs, ... }:
    #let
    #  lock = "${lib.getExe pkgs.swaylock-effects} -C /home/earn/.dotfiles/swaylock/rose-pine --clock --indicator-idle-visible";
    #  display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
    #in
    {
      imports = [
        self.nixosModules.niri
        self.nixosModules.displayManager
        #inputs.sysc-greet.nixosModules.default
      ];

      environment.systemPackages = with pkgs; [
        waybar
        swaynotificationcenter
        kdePackages.polkit-kde-agent-1
      ];

      services.hypridle.enable = true;
      programs.hyprlock.enable = true;

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

      # Existing display-off/on cycle around locking is intentionally unchanged.
      #systemd.user.services.swayidle = {
      #  description = "swayidle";
      #  partOf = [ "graphical-session.target" ];
      #  after = [ "graphical-session.target" ];
      #  requisite = [ "graphical-session.target" ];
      #  serviceConfig = {
      #    ExecStart =
      #      "${lib.getExe pkgs.swayidle}"
      #      + " -w"
      #      + " timeout 290 '${pkgs.libnotify}/bin/notify-send \"Locking in 5 seconds\" -t 5000'"
      #      + " timeout 300 '${lock} -f'"
      #      + " timeout 310 '${display "off"}'"
      #      #+ " timeout 320 '${pkgs.systemd}/bin/systemctl suspend'"
      #      + " resume '${display "on"}'";
      #    #+ " before-sleep '${lock} -f'";
      #    Restart = "on-failure";
      #  };
      #  wantedBy = [ "graphical-session.target" ];
      #};

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

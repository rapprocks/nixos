{ self, inputs, ... }: {
  flake.nixosModules.slimniri = { lib, pkgs, ... }:
    let
      lock = "${lib.getExe pkgs.swaylock-effects} -C /home/earn/.dotfiles/swaylock/rose-pine --clock --indicator-idle-visible";
      display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
    in
    {
      imports = [
        self.nixosModules.niri
        inputs.sysc-greet.nixosModules.default
      ];

      environment.systemPackages = with pkgs; [
        waybar
        swaynotificationcenter
        kdePackages.polkit-kde-agent-1
      ];

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
      systemd.user.services.swayidle = {
        description = "swayidle";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        requisite = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart =
            "${lib.getExe pkgs.swayidle}"
            + " -w"
            + " timeout 290 '${pkgs.libnotify}/bin/notify-send \"Locking in 5 seconds\" -t 5000'"
            + " timeout 300 '${lock} -f'"
            + " timeout 310 '${display "off"}'"
            #+ " timeout 320 '${pkgs.systemd}/bin/systemctl suspend'"
            + " resume '${display "on"}'";
          #+ " before-sleep '${lock} -f'";
          Restart = "on-failure";
        };
        wantedBy = [ "graphical-session.target" ];
      };

      systemd.user.services.polkit-kde-agent-1 = {
        description = "polkit-kde-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

      security.pam.services = {
        greetd.fprintAuth = false;
      };

      services.sysc-greet = {
        enable = true;
        compositor = "niri";
        settings.initial_session = {
          command = "niri";
          user = "earn";
        };
      };

      services.dotfiles = {
        mappings = {
          ".config/swaync/config.json" = "swaync/config.json";
        };
        themedMappings.".config/swaync/style.css" = {
          dark = "swaync/rose-pine.css";
          light = "swaync/rose-pine-dawn.css";
        };
      };
    };
}

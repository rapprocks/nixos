## NOTE NOTE NOTE!! Currently some wierd stuff with sleep. lockscreen->displays off-> displays on -> lockscreen -> displays off and suspend ###
{ ... }:
{
  flake.nixosModules.swayidle =
    { lib, pkgs, ... }:
    let
      lock = "${lib.getExe pkgs.swaylock-effects} -C /home/earn/.dotfiles/swaylock/rose-pine --clock";
      display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
    in
    {
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
      environment.systemPackages = with pkgs; [
        swaylock-effects
      ];
    };
}

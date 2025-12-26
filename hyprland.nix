{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    hyprcursor
  ];

  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  programs.hyprlock.enable = true;
  services.hypridle.enable = true;
}

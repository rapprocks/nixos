{ inputs, ... }:
{
  imports = [
    inputs.dms.nixosModules.dank-material-shell
  ];
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
  };
}

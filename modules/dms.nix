{
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.profiles.dms;
in {
  imports = [ inputs.dms.nixosModules.dank-material-shell ];
  
  options.profiles.dms.enable = lib.mkEnableOption "Dank Material Shell";

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      enable = true;
      systemd.enable = true;
    };
  };
}
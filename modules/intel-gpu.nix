{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profiles.intelGpu;
in {
  options.profiles.intelGpu = {
    enable = lib.mkEnableOption "Intel integrated GPU support";
    forceProbe = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "a7a1";
      description = "Force probe for specific Intel GPU device ID";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = ["i915"];
    boot.kernelParams = lib.mkIf (cfg.forceProbe != null) [
      "i915.force_probe=${cfg.forceProbe}"
    ];
    hardware.graphics.extraPackages = [pkgs.vpl-gpu-rt];
  };
}
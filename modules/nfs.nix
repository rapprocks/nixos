{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profiles.nfs;
  nasHost = "10.100.0.4";
  remoteBase = "/mnt/tank";
  localBase = "/mnt/nas";
in {
  options.profiles.nfs = {
    shares = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["documents" "media/movies"];
      description = "List of TrueNAS shares to mount";
    };
  };

  config = lib.mkIf (cfg.shares != []) {
    environment.systemPackages = [pkgs.nfs-utils];

    fileSystems = lib.genAttrs cfg.shares (share: {
      device = "${nasHost}:${remoteBase}/${share}";
      fsType = "nfs";
      mountPoint = "${localBase}/${share}";
      options = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=600"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "noatime"
      ];
    });
  };
}

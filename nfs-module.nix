{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  nasHost = "10.100.0.4";
  remoteBase = "/mnt/tank";
  localBase = "/mnt/nas";

  cfg = config.my.nfs;
in {
  options.my.nfs = {
    shares = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of TrueNAS shares to mount.";
    };
  };

  config = mkIf (cfg.shares != []) {
    environment.systemPackages = [pkgs.nfs-utils];

    fileSystems = genAttrs cfg.shares (share: {
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

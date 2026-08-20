{ ... }:
{
  flake.nixosModules.nasMounts =
    { pkgs, lib, ... }:
    let
      nasHost = "10.100.0.4";
      remoteBase = "/mnt/tank";
      localBase = "/mnt/nas";
      shares = [
        "documents"
        "downloads/torrents"
        "media/movies"
        "media/tv"
      ];
    in
    {
      environment.systemPackages = [ pkgs.nfs-utils ];

      fileSystems = lib.genAttrs shares (share: {
        device = "${nasHost}:${remoteBase}/${share}";
        fsType = "nfs";
        mountPoint = "${localBase}/${share}";
        options = [
          "x-systemd.automount"
          "nfsvers=4.2"
          "proto=tcp"
          "hard"
          "noauto"
          "x-systemd.idle-timeout=600"
          "noatime"
        ];
      });
    };
}

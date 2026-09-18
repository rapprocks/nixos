{ ... }:
{
  flake.nixosModules.nasMounts =
    { pkgs, lib, ... }:
    let
      nasHost = "10.100.0.4";
      remoteBase = "/mnt/tank";
      remoteBaseChonk = "/mnt/chonk/data";
      localBase = "/mnt/nas";
      shares = [
        "documents"
        "downloads/torrents"
        "media/movies"
        "media/tv"
      ];
      chonkShares = {
        new-media-tv = "media/tv";
        new-media-movies = "media/movies";
      };
      mountOptions = [
        "x-systemd.automount"
        "nfsvers=4.2"
        "proto=tcp"
        "hard"
        "noauto"
        "x-systemd.idle-timeout=86400"
        "noatime"
      ];
      chonkMounts = lib.mapAttrs (localName: remotePath: {
        device = "${nasHost}:${remoteBaseChonk}/${remotePath}";
        fsType = "nfs";
        mountPoint = "${localBase}/${localName}";
        options = mountOptions;
      }) chonkShares;
    in
    {
      environment.systemPackages = [ pkgs.nfs-utils ];

      fileSystems =
        (lib.genAttrs shares (share: {
          device = "${nasHost}:${remoteBase}/${share}";
          fsType = "nfs";
          mountPoint = "${localBase}/${share}";
          options = mountOptions;
        }))
        // chonkMounts;
    };
}

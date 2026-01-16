{...}: {
  imports = [./hardware-configuration.nix];

  networking.hostName = "zeus";

  boot.initrd.luks.devices."luks-dace8e36-8066-4406-b113-a93b047bf55d".device =
    "/dev/disk/by-uuid/dace8e36-8066-4406-b113-a93b047bf55d";

  profiles = {
    laptop.enable = true;
    intelGpu = {
      enable = true;
      forceProbe = "a7a1";
    };
    nfs.shares = ["documents" "downloads/torrents" "media/movies" "media/tv"];
    security = {
      yubikey.enable = true;
      fingerprint.enable = true;
    };
  };

  system.stateVersion = "25.11";
}
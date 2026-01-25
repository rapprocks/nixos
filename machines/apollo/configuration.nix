{ username, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "apollo";

  hardware.amdgpu.initrd.enable = true;
  services.xserver.videoDrivers = [ "modesetting" ];

  programs.steam.enable = true;

  profiles = {
    nfs.shares = [
      "documents"
      "downloads/torrents"
      "media/movies"
      "media/tv"
    ];
    virtualization.enable = true;
    security = {
      yubikey.enable = true;
      fingerprint.enable = false;
    };
  };

  system.stateVersion = "25.05";
}

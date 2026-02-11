{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  time.timeZone = "Europe/Stockholm";

  networking.hostName = "apollo";

  hardware.amdgpu.initrd.enable = true;
  services.xserver.videoDrivers = [ "modesetting" ];

  programs.steam.enable = true;

  programs.ssh.extraConfig = ''
    	Host prod-hel-vps-1.duckdns.org
        User admin
        Port 33001
        ControlMaster auto
        ControlPath ~/.ssh/cm-%r@%h:%p
        ControlPersist 15m
  '';

  profiles = {
    displayManager.autoLogin = false;
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

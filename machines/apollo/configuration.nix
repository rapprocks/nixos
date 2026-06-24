{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  time.timeZone = "Europe/Stockholm";

  networking.hostName = "apollo";
  networking.nameservers = [ "10.100.0.62" ];

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
    gdm.enable = true;
    gdm.autoLogin = false;
    nfs.shares = [
      "documents"
      "downloads/torrents"
      "media/movies"
      "media/tv"
    ];
    ollama = {
      enable = true;
      models = [
        "gemma4:e4b"
        "qwen2.5:7B"
      ];
    };
    virtualization.enable = true;
    security = {
      yubikey.enable = true;
      fingerprint.enable = false;
    };
  };

  system.stateVersion = "25.05";
}

{username, ...}: {
  imports = [./hardware-configuration.nix];

  networking.hostName = "apollo";

  hardware.amdgpu.initrd.enable = true;
  services.xserver.videoDrivers = ["modesetting"];

  programs.steam.enable = true;

  profiles = {
    nfs.shares = ["documents" "downloads/torrents" "media/movies" "media/tv"];
    virtualization.enable = true;
    security = {
      yubikey.enable = true;
      fingerprint.enable = false;
    };
  };

  # Extra groups for virtualization
  users.users.${username} = {
    extraGroups = ["libvirtd" "kvm"];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIN/ErsadQDu44JW5V94RUCKrbeieyuE440kHLWDdnx28AAAACXNzaDpuaXhvcw== ext.rapp@gmail.com"
    ];
  };

  system.stateVersion = "25.05";
}

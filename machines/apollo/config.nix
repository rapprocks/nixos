{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../nfs-module.nix
  ];

  networking.hostName = "apollo"; # Define your hostname.

  my.nfs.shares = [
    "documents"
    "downloads/torrents"
    "media/movies"
    "media/tv"
  ];

  programs.steam.enable = true;

  hardware.amdgpu.initrd.enable = true;
  services.xserver.videoDrivers = ["modesetting"];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.earn = {
    isNormalUser = true;
    description = "earn";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
    ];
  };
  # Enable tailscale
  services.tailscale.enable = true;

  services.syncthing = {
    user = "earn"; # Change per-host if needed, or use a variable
    dataDir = "/home/earn";
  };

  system.stateVersion = "25.05";
}

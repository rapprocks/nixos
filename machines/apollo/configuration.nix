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
      "libvirtd" # Virtualisation
      "kvm" # Virtualisation
    ];
    openssh.authorizedKeys.keys = ["sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIN/ErsadQDu44JW5V94RUCKrbeieyuE440kHLWDdnx28AAAACXNzaDpuaXhvcw== ext.rapp@gmail.com"];
  };
  # Enable tailscale
  services.tailscale.enable = true;

  services.syncthing = {
    user = "earn"; # Change per-host if needed, or use a variable
    dataDir = "/home/earn";
  };

  # Virtualisation

  environment.systemPackages = with pkgs; [
    qemu
    OVMF
    swtpm
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Optional but recommended
  virtualisation.spiceUSBRedirection.enable = true;

  # UEFI firmware for Windows 11
  virtualisation.libvirtd.qemu = {
    #ovmf.enable = true;
    swtpm.enable = true;
  };

  system.stateVersion = "25.05";
}

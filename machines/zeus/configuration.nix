{
  pkgs,
  username,
  ...
}: {
  imports = [./hardware-configuration.nix ../../nfs-module.nix];

  networking.hostName = "zeus"; # ← matches flake definition

  my.nfs.shares = [
    "documents"
    "downloads/torrents"
    "media/movies"
    "media/tv"
  ];

  # Hardware-specific
  boot.kernelParams = ["i915.force_probe=a7a1"];
  boot.initrd.kernelModules = ["i915"];
  hardware.graphics.extraPackages = [pkgs.vpl-gpu-rt];

  boot.initrd.luks.devices."luks-dace8e36-8066-4406-b113-a93b047bf55d".device = "/dev/disk/by-uuid/dace8e36-8066-4406-b113-a93b047bf55d";

  # Syncthing
  services.syncthing = {
    user = "${username}";
    dataDir = "/home/${username}";
  };

  # Laptop power management
  services.logind.settings.Login = {
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };
  services.power-profiles-daemon.enable = false;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # User
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel" "input"];
  };

  system.stateVersion = "25.05";
}

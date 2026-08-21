{
  pkgs,
  username,
  ...
}: {
  imports = [./hardware-configuration.nix];

  networking.hostName = "nix"; # ← matches flake definition

  # Hardware-specific
  boot.kernelParams = ["i915.force_probe=a7a1"];
  boot.initrd.kernelModules = ["i915"];
  hardware.graphics.extraPackages = [pkgs.vpl-gpu-rt];

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

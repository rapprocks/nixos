{
  pkgs,
  username,
  ...
}: {
  imports = [./hardware-configuration.nix];

  networking.hostName = "nixwrk"; # ← matches flake definition

  # Hardware-specific
  boot.kernelParams = ["i915.force_probe=46a8"];
  boot.initrd.kernelModules = ["i915"];
  boot.initrd.luks.devices."luks-59f0c2b6-2617-42dc-884a-35acdd0c44c6".device = "/dev/disk/by-uuid/59f0c2b6-2617-42dc-884a-35acdd0c44c6";

  hardware.graphics.extraPackages = [pkgs.vpl-gpu-rt];

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
    extraGroups = ["networkmanager" "wheel" "input" "plugdev"];
  };

  system.stateVersion = "25.11";
}

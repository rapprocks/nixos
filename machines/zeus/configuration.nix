{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  services.automatic-timezoned.enable = true;

  environment.systemPackages = with pkgs; [
    hypnotix
  ];

  networking.hostName = "zeus";

  boot.initrd.luks.devices."luks-dace8e36-8066-4406-b113-a93b047bf55d".device =
    "/dev/disk/by-uuid/dace8e36-8066-4406-b113-a93b047bf55d";

  profiles = {
    displayManager.autoLogin = true;
    laptop.enable = true;
    intelGpu = {
      enable = true;
      forceProbe = "a7a1";
    };
    nfs.shares = [
      "documents"
      "downloads/torrents"
      "media/movies"
      "media/tv"
    ];
    security = {
      yubikey.enable = true;
      fingerprint.enable = true;
    };
    tailnet.enable = true;
  };

  # Remaps for tenforty laptop keyboard
  services.keyd = {
    enable = true;
    keyboards = {
      "tenforty" = {
        ids = [ "0001:0001" ];
        settings = {
          main = {
            pageup = "left";
            pagedown = "right";
            capslock = "escape";
            #leftalt = "leftmeta";
            #leftmeta = "leftalt";
          };
        };
      };
    };
  };

  system.stateVersion = "25.11";
}

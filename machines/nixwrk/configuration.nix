{ pkgs, username, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixwrk";

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
    enableSSHSupport = true;
  };

  programs.zsh.interactiveShellInit = ''
    export GPG_TTY=$(tty)
  '';

  programs.zsh.shellInit = ''eval "$(aw autocomplete:script zsh)"'';

  boot.initrd.luks.devices."luks-59f0c2b6-2617-42dc-884a-35acdd0c44c6".device =
    "/dev/disk/by-uuid/59f0c2b6-2617-42dc-884a-35acdd0c44c6";

  profiles = {
    laptop.enable = true;
    virtualization.enable = true;
    intelGpu = {
      enable = true;
      forceProbe = "46a8";
    };
    security = {
      yubikey.enable = true;
      fingerprint.enable = true;
    };
  };

  system.stateVersion = "25.11";
}

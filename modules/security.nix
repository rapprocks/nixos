{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.profiles.security;
in
{
  options.profiles.security = {
    yubikey.enable = lib.mkEnableOption "YubiKey U2F/FIDO2 authentication";
    fingerprint.enable = lib.mkEnableOption "fingerprint authentication";
  };

  config = lib.mkMerge [
    # YubiKey support
    (lib.mkIf cfg.yubikey.enable {
      security.pam.u2f = {
        enable = true;
        settings = {
          cue = true;
          pinverification = 1;
        };
      };

      security.pam.services = {
        login.u2fAuth = false;
        sudo.u2fAuth = true;
      };

      services.pcscd.enable = true;

      services.udev.packages = with pkgs; [
        libfido2
        yubikey-personalization
      ];

      users.groups.plugdev = { };

      environment.systemPackages = with pkgs; [
        yubikey-manager
        libfido2
        yubioath-flutter
      ];
    })

    # Fingerprint support
    (lib.mkIf cfg.fingerprint.enable {
      services.fprintd.enable = true;

      systemd.services.fprintd = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "2s";
          StartLimitIntervalSec = 0;
        };
      };

      # udev rule to prevent USB autosuspend on the fingerprint reader
      services.udev.extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00f0", ATTR{power/control}="on", ATTR{power/autosuspend}="-1"
      '';

      security.pam.services.ly.fprintAuth = false;
      security.pam.services.login.fprintAuth = false;

      security.pam.services.fprintd.enable = true;
      # Only enable fingerprint auth for specific services - NOT login/display manager
      security.pam.services.hyprlock.fprintAuth = true;
      # Optionally for sudo (can be slow if reader doesn't respond):
      security.pam.services.sudo.fprintAuth = true;
    })
  ];
}

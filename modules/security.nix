{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profiles.security;
in {
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
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };

      services.pcscd.enable = true;

      services.udev.packages = with pkgs; [
        libfido2
        yubikey-personalization
      ];

      users.groups.plugdev = {};

      environment.systemPackages = with pkgs; [
        yubikey-manager
        libfido2
        yubioath-flutter
      ];
    })

    # Fingerprint support
    (lib.mkIf cfg.fingerprint.enable {
      services.fprintd.enable = true;

      security.pam.services = {
        login.fprintAuth = true;
        sudo.fprintAuth = true;
      };
    })
  ];
}
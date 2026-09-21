{ ... }: {
  flake.nixosModules.system = { ... }: {

    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1d";
    };

    users.users.earn = {
      isNormalUser = true;
      description = "earn";
      extraGroups = [
        "networkmanager"
        "wheel"
        "plugdev"
      ];
    };

    programs.nix-ld.enable = true;

    networking.networkmanager.enable = true;
    services.openssh.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/Stockholm";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "sv_SE.UTF-8";
      LC_IDENTIFICATION = "sv_SE.UTF-8";
      LC_MEASUREMENT = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
      LC_NAME = "sv_SE.UTF-8";
      LC_NUMERIC = "sv_SE.UTF-8";
      LC_PAPER = "sv_SE.UTF-8";
      LC_TELEPHONE = "sv_SE.UTF-8";
      LC_TIME = "sv_SE.UTF-8";
    };

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "se";
      variant = "nodeadkeys";
    };

    # Configure console keymap
    console.keyMap = "sv-latin1";

  };
}

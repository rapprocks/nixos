{ ... }: {
  flake.nixosModules.nixos = { ... }: {
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

    system.stateVersion = "26.05"; # Did you read the comment?

  };
}

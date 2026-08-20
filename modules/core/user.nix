{ ... }: {
  flake.nixosModules.user = { ... }: {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users."earn" = {
      isNormalUser = true;
      description = "earn";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}

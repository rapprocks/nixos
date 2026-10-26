{ ... }:
{
  # Additional user: import in a host's configuration to add philip there.
  flake.nixosModules.userPhilip =
    { ... }:
    {
      preferences.user.extraUsers = [ "philip" ];
      users.users.philip.description = "Philip";

      # User-specific dotfiles: target (relative to home) = source (relative to ~/.dotfiles).
      services.dotfiles.users.philip.mappings = { };
    };
}

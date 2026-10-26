{ ... }:
{
  # Primary user: present on every host through the workstation profile.
  flake.nixosModules.userEarn =
    {
      config,
      lib,
      ...
    }:
    let
      user = config.preferences.user.name;
    in
    {
      users.users.${user}.description = lib.mkDefault user;
      services.dotfiles.users.${user}.mappings = { };
    };
}

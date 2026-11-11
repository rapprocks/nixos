{ ... }:
{
  # Additional user: import in a host's configuration to add philip there.
  flake.nixosModules.userPhilip =
    { config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      preferences.user.extraUsers = [ "philip" ];
      users.users.philip.description = "Philip";

      programs.zsh.interactiveShellInit = ''
        if [[ "$USER" == "philip" ]] && command -v aw >/dev/null 2>&1; then
          eval "$(aw autocomplete:script zsh)"
        fi
      '';

      # TODO: Add work-specific settings here as needed (VPN client, corporate certs, work browser profile, etc.)

      services.dotfiles.users.${user}.mappings = {
        ".config/waybar/nixwork.jsonc" = "waybar/nixwork.jsonc";
      };
    };
}

{ ... }:
{
  # Additional user: import in a host's configuration to add philip there.
  flake.nixosModules.userPhilip =
    {
      config,
      lib,
      ...
    }:
    {
      users.users.philip = {
        isNormalUser = true;
        description = "Philip";
        initialPassword = "sommartorp1";
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "plugdev"
          "keys"
        ]
        ++ lib.optional (config.virtualisation.libvirtd.enable or false) "libvirtd"
        ++ lib.optional (config.virtualisation.libvirtd.enable or false) "kvm"
        ++ lib.optional (config.virtualisation.docker.enable or false) "docker";
      };

      # User-specific dotfiles: target (relative to home) = source (relative to ~/.dotfiles).
      services.dotfiles.users.philip.mappings = { };
    };
}

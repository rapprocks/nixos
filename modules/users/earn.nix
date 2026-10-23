{ ... }:
{
  # Primary user: present on every host through the workstation profile.
  flake.nixosModules.userEarn =
    {
      config,
      lib,
      ...
    }:
    {
      users.users.earn = {
        isNormalUser = true;
        description = "earn";
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "plugdev"
          "keys"
          "drop"
        ]
        ++ lib.optional (config.virtualisation.libvirtd.enable or false) "libvirtd"
        ++ lib.optional (config.virtualisation.libvirtd.enable or false) "kvm"
        ++ lib.optional (config.virtualisation.docker.enable or false) "docker";
      };

      # User-specific dotfiles: target (relative to home) = source (relative to ~/.dotfiles).
      services.dotfiles.users.earn.mappings = { };
    };
}

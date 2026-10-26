{ ... }:
{
  flake.nixosModules.preferences =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.preferences;
      defaultUserGroups =
        [
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
    in
    {
      options.preferences = {
        user = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "earn";
            description = "Primary username for this host.";
          };

          home = lib.mkOption {
            type = lib.types.str;
            default = config.users.users.${cfg.user.name}.home;
            readOnly = true;
            description = "Home directory of the primary user.";
          };

          extraUsers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional normal usernames enabled on this host.";
          };

          allUsers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = lib.unique ([ cfg.user.name ] ++ cfg.user.extraUsers);
            readOnly = true;
            description = "All normal usernames provisioned on this host (primary + extraUsers).";
          };
        };

        host = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Hostname for this machine (automatically sets networking.hostName).";
          };

          isWork = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this host uses work profile policies.";
          };
        };
      };

      config = {
        networking.hostName = cfg.host.name;

        users.users = lib.genAttrs cfg.user.allUsers (u: {
          isNormalUser = true;
          description = lib.mkDefault u;
          extraGroups = defaultUserGroups;
        });

        services.dotfiles.users = lib.genAttrs cfg.user.allUsers (_: {
          mappings = lib.mkDefault { };
        });
      };
    };
}

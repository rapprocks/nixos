{ ... }:
{
  flake.nixosModules.syncthing =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.services.syncthingSync;
    in
    {
      options.services.syncthingSync = {
        enable = lib.mkEnableOption "Custom Declarative Syncthing";
        user = lib.mkOption {
          type = lib.types.str;
          default = "earn";
          description = "User to run Syncthing as.";
        };
        folders = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  description = "Unique Syncthing folder ID.";
                };
                path = lib.mkOption {
                  type = lib.types.str;
                  description = "Filesystem path to sync.";
                };
                devices = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "List of device names to sync with.";
                };
                mode = lib.mkOption {
                  type = lib.types.str;
                  default = "0750";
                  description = "Directory permission mode (octal string).";
                };
              };
            }
          );
          default = { };
          description = "Syncthing folders to sync across devices.";
        };
      };

      config = lib.mkIf cfg.enable {
        # 1. SOPS Secret for the GUI plaintext password
        sops.secrets."syncthing_gui_password" = {
          owner = cfg.user;
        };

        # 2. Ensure synced folders exist with correct permissions before syncthing starts
        systemd.tmpfiles.rules = lib.mapAttrsToList (
          _: folder: "d ${folder.path} ${folder.mode} ${cfg.user} ${cfg.user} - -"
        ) cfg.folders;

        # 3. Native Syncthing Configuration
        services.syncthing = {
          enable = true;
          user = cfg.user;
          dataDir = "/home/${cfg.user}/.local/share/syncthing";
          configDir = "/home/${cfg.user}/.config/syncthing";

          # Enforce declarative state (GUI cannot deviate from Nix)
          overrideDevices = true;
          overrideFolders = true;

          # Open transfer (22000) and discovery (21027) firewall ports
          openDefaultPorts = true;

          # Pass the decrypted sops secret file path.
          # Syncthing automatically hashes this with bcrypt at service startup.
          guiPasswordFile = config.sops.secrets."syncthing_gui_password".path;

          settings = {
            gui = {
              user = cfg.user;
            };

            # Global device list
            devices = {
              "zeus" = {
                id = "OL4E44O-GFP6ZSD-YH4RVOD-7QOWF75-GQG4NIG-LA3TOTI-HFXARMC-4GFBZQA";
              };
              "nixwork" = {
                id = "4UPYDTM-2UQEA52-CDPE6EE-BG2JHE7-V2FN6QP-W6U34H2-NY7VWBW-O3GJVAT";
              };
              "truenas" = {
                id = "6KETVV7-J3HRFXX-UZ3UE5X-4ORVPJZ-OY4TY4U-QIDWD5R-QUNN4ZX-EFNYSQG";
                #addresses = [ "tcp://10.100.0.4:22000" ];
              };
            };

            # Folders to sync - generated from cfg.folders option
            folders = lib.mapAttrs (name: folder: {
              id = folder.id;
              path = folder.path;
              devices = folder.devices;
            }) cfg.folders;

            options = {
              urAccepted = -1; # Disable anonymous usage reporting
            };
          };
        };

        # 4. Ensure syncthing service starts after tmpfiles setup
        systemd.services.syncthing = {
          after = [ "systemd-tmpfiles-setup.service" ];
          wants = [ "systemd-tmpfiles-setup.service" ];
        };
      };
    };
}

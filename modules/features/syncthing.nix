{ self, inputs, ... }:
{
  flake.nixosModules.syncthing =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.services.customSyncthing;

      # 1. Global registry of devices on your network
      devices = {
        "zeus" = {
          id = "DEVICE-ID-FOR-ZEUS-AAAAAAA-BBBBBBB-...";
          addresses = [
            "tcp://10.100.0.X:22000"
            "dynamic"
          ];
        };
      };

      # 2. Global registry of shared folders
      # Specify which devices participate in each folder
      allFolders = {
        "documents" = {
          id = "sync-documents";
          path = "/home/${cfg.user}/Documents";
          devices = [
            "zeus"
            "kde"
            "truenas"
          ];
          # File versioning strategy
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "2592000"; # 30 days
            };
          };
        };
        "notes" = {
          id = "sync-notes";
          path = "/home/${cfg.user}/Notes";
          devices = [
            "zeus"
            "kde"
            "truenas"
          ];
          versioning = {
            type = "simple";
            params = {
              keep = "10";
            };
          };
        };
        "projects" = {
          id = "sync-projects";
          path = "/home/${cfg.user}/Projects";
          devices = [
            "zeus"
            "kde"
            "truenas"
          ];
          ignorePerms = false;
        };
      };

      currentHost = config.networking.hostName;

      # Filter out the current device from the devices list (Syncthing requirement)
      otherDevices = lib.filterAttrs (name: _: name != currentHost) devices;

      # Filter folders to only include those relevant to this host
      hostFolders = lib.filterAttrs (_: folder: builtins.elem currentHost folder.devices) (
        lib.mapAttrs (
          name: folder:
          folder
          // {
            # Remove current host from the folder's device list
            devices = builtins.filter (dev: dev != currentHost) folder.devices;
          }
        ) allFolders
      );
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      options.services.customSyncthing = {
        enable = lib.mkEnableOption "Custom Declarative Syncthing";
        user = lib.mkOption {
          type = lib.types.str;
          default = "earn";
          description = "User to run Syncthing under.";
        };
        guiAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:8384";
          description = "Address for the Web GUI.";
        };
      };

      config = lib.mkIf cfg.enable {
        # 1. Setup SOPS Secret
        sops.defaultSopsFile = ../../secrets/syncthing.yaml;
        sops.secrets."syncthing/gui_password" = {
          owner = cfg.user;
        };

        # 2. Configure Native Syncthing Service
        services.syncthing = {
          enable = true;
          user = cfg.user;
          dataDir = "/home/${cfg.user}/.local/share/syncthing";
          configDir = "/home/${cfg.user}/.config/syncthing";
          guiAddress = cfg.guiAddress;
          openDefaultPorts = true; # Opens TCP/UDP 22000 and UDP 21027

          # Strict declarative sync
          overrideDevices = true;
          overrideFolders = true;

          settings = {
            devices = otherDevices;
            folders = hostFolders;
            gui = {
              # Use password hash from sops secret or configure via settings
              user = "earn";
            };
            options = {
              urAccepted = -1; # Disable telemetry/usage reporting
              relaysEnabled = true;
              localAnnounceEnabled = true;
            };
          };
        };

        # 3. Ensure required directories exist with correct ownership
        systemd.services.syncthing.preStart = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (_: folder: ''
            mkdir -p "${folder.path}"
            chown -R ${cfg.user}:${config.users.users.${cfg.user}.group} "${folder.path}"
          '') hostFolders
        );
      };
    };
}

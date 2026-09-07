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
      #imports = [
      #  inputs.sops-nix.nixosModules.sops
      #];
      options.services.syncthingSync = {
        enable = lib.mkEnableOption "Custom Declarative Syncthing";
        user = lib.mkOption {
          type = lib.types.str;
          default = "earn";
          description = "User to run Syncthing as.";
        };
      };

      config = lib.mkIf cfg.enable {
        # 1. SOPS Secret for the GUI plaintext password
        sops.secrets."syncthing_gui_password" = {
          owner = cfg.user;
        };

        # 2. Native Syncthing Configuration
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
              #"kde" = {
              #  id = "KDE-DEVICE-ID-HERE";
              #};
              #"truenas" = {
              #  id = "TRUENAS-DEVICE-ID-HERE";
              #  addresses = [ "tcp://10.100.0.4:22000" ];
              #};
            };

            # Folders to sync
            folders = {
              #"Documents" = {
              #  id = "sync-documents";
              #  path = "/home/${cfg.user}/Documents";
              #  devices = [
              #    "zeus"
              #    "kde"
              #    "truenas"
              #  ];
              #};
              "Notes" = {
                id = "sync-notes";
                path = "/home/${cfg.user}/Documents/Notes";
                devices = [
                  "zeus"
                  #"kde"
                  #"truenas"
                ];
              };
            };

            options = {
              urAccepted = -1; # Disable anonymous usage reporting
            };
          };
        };
      };
    };
}

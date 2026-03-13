{
  lib,
  config,
  ...
}:
let
  cfg = config.profiles.borgbackup;
  host =
    if cfg.storagebox.host != ""
    then cfg.storagebox.host
    else "${cfg.storagebox.user}.your-storagebox.de";
  repo = "ssh://${cfg.storagebox.user}@${host}:${toString cfg.storagebox.port}/${cfg.storagebox.subPath}";
in
{
  options.profiles.borgbackup = {
    enable = lib.mkEnableOption "BorgBackup to Hetzner Storage Box";

    storagebox = {
      user = lib.mkOption {
        type = lib.types.str;
        example = "u123456";
        description = "Hetzner Storage Box SSH username";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Storage Box hostname (defaults to <user>.your-storagebox.de)";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 23;
        description = "SSH port for Hetzner Storage Box";
      };

      subPath = lib.mkOption {
        type = lib.types.str;
        default = "./borg/${config.networking.hostName}";
        description = "Relative path inside the storage box for this host's repo";
      };
    };

    sshKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the SSH private key for storage box authentication (must be readable by root)";
    };

    passphraseFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the Borg repository passphrase";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home"
        "/etc/nixos"
        "/var/lib"
      ];
      description = "Paths to back up";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "*.pyc"
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/Downloads"
        "/home/*/.mozilla/firefox/*/storage"
        "/home/*/.config/Brave*/*/Service Worker/CacheStorage"
        "/var/lib/docker"
        "/var/lib/containers"
      ];
      description = "Patterns to exclude from backup";
    };

    startAt = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      example = "*-*-* 03:00:00";
      description = "Systemd calendar expression for backup schedule";
    };

    prune = {
      within = lib.mkOption {
        type = lib.types.str;
        default = "1d";
        description = "Keep all archives within this time span";
      };
      daily = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of daily archives to keep";
      };
      weekly = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of weekly archives to keep";
      };
      monthly = lib.mkOption {
        type = lib.types.int;
        default = 6;
        description = "Number of monthly archives to keep";
      };
      yearly = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of yearly archives to keep";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.borgbackup.jobs."hetzner" = {
      inherit (cfg) paths exclude startAt;

      repo = repo;

      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${cfg.passphraseFile}";
      };

      environment.BORG_RSH = "ssh -i ${cfg.sshKeyFile} -o StrictHostKeyChecking=accept-new";

      compression = "auto,zstd";

      prune.keep = {
        inherit (cfg.prune) within daily weekly monthly yearly;
      };

      persistentTimer = true;

      extraCreateArgs = "--stats --one-file-system";
      extraPruneArgs = "--stats --list";
    };
  };
}
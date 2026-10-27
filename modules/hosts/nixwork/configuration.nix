{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.nixwork = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.nixworkConfig ];
  };

  flake.nixosModules.nixworkConfig = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.nixworkHardware
      self.nixosModules.workstation
      self.nixosModules.userPhilip
      self.nixosModules.work
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
      self.nixosModules.sysse-loki-report
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ];

    services.sysadminLokiReport = {
      enable = true;
      # Override the prompt anytime:
      prompt = ''
        Analyze the logs for `{owner="sysadmin"}` in Grafana Loki datasource `loki-dev-hz1` (`uid: idlqk6HVk`), comparing the last 24 hours against the 14-day baseline.

        Follow these steps using the Grafana MCP Loki tools:
          1. **Volume & Baseline Comparison (14d vs 24h)**:
            - Run instant metric queries using `sum by (service, level) (count_over_time({owner="sysadmin"}[14d]))` (or chunked if hit by Loki limits) and `sum by (service, level) (count_over_time({owner="sysadmin"}[24h]))`.
            - Calculate the 14-day daily average (`14d_count / 14`) per service and compare it against the last 24h count.
            - Flag any service where 24h volume spiked (>2x daily average), dropped unexpectedly (e.g., stopped logging), or started emitting a new `level` (such as `error` or `critical`).

          2. **Error & Warning Investigation (Last 24h)**:
            - Query log streams from the last 24h (excluding noisy `*-connect-proxy` 200 OK health/prometheus checks) for:
            - `{owner="sysadmin", level=~"error|critical|warning"}`
            - `{owner="sysadmin", service!~".*-connect-proxy"} |~ "(?i)error|warn|fail|panic|exception|fatal"`
            - For any error/warning pattern found in the last 24h, check whether it is a **new issue** (appeared only in the last 24h) or a **chronic/recurring issue** (present across the 14d window).

          3. **Output Format (concise Markdown)**:
            - **Executive Summary**: 2–3 bullet points on overall health and whether immediate attention is needed.
            - **Anomalies & Inconsistencies (24h vs 14d Avg)**: Table showing `Service | 24h Logs | 14d Daily Avg | Delta / Status` for services with notable changes or errors.
            - **New Issues (Last 24h)**: Errors or warnings that newly appeared or spiked in the last 24h, with sample log lines and affected host/service.
            - **Chronic / Recurring Issues**: Known ongoing warnings/errors (e.g., Consul memberlist, XA recovery, SSH scanner noise) summarized briefly with counts so they don't clutter new findings.
      '';
      # Optional:
      schedule = "*-*-* 08:30:00";
      # outputFile = "$HOME/Documents/sysadmin-weekly-report.md";
      # webhookUrlFile = config.sops.secrets.chat_webhook.path;
    };

    preferences = {
      host.name = "nixwork";
      user.name = "earn";
      user.extraUsers = [ "philip" ];
    };

    sops.secrets.librenms_api_token = {
      owner = config.preferences.user.name;
      group = "keys";
      mode = "0440";
    };

    environment.systemPackages = with pkgs; [
      ngrok
      amdtop
    ];

    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.luks.devices."luks-e23c56ef-712d-4c70-9b40-525e09217a72".device =
      "/dev/disk/by-uuid/e23c56ef-712d-4c70-9b40-525e09217a72";

    hardware.laptop.enable = true;

    ### Custom NixOS options ###

    services.desktopApps = {
      "google-chat" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/google-chat.desktop";
        iconPath = "~/.dotfiles/apps/icons/google-chat.png";
      };
      "google-calendar" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/google-calendar.desktop";
        iconPath = "~/.dotfiles/apps/icons/google-calendar.png";
      };
      "google-gemini" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/gemini.desktop";
        iconPath = "~/.dotfiles/apps/icons/google-gemini.png";
      };
      "spotify" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/spotify.desktop";
        iconPath = "~/.dotfiles/apps/icons/spotify.png";
      };
      "theme" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/theme.desktop";
        iconPath = "~/.dotfiles/apps/icons/theme.png";
      };
      "bluetui" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/bluetui.desktop";
        iconPath = "~/.dotfiles/apps/icons/bluetui.png";
      };
      "librenms" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/libre.desktop";
        iconPath = "~/.dotfiles/apps/icons/librenms.png";
      };
      "wireguard" = {
        enable = true;
        sourcePath = "~/.dotfiles/apps/wg-work.desktop";
        iconPath = "~/.dotfiles/apps/icons/wireguard.png";
      };
    };

    # Enable Wi-Fi and Syncthing for this work host
    networking.enabledWifiNetworks = [
      "k69"
      "work"
    ];

    services.virtualisation.enable = true;
    services.docker.enable = true;
    # Multiple users on this host: no auto-login, greetd shows the login prompt.
    services.dm.greetd = {
      enable = true;
      autoLogin = false;
    };

    services.agentic = {
      enable = true;
      acceleration = "vulkan"; # Radeon 890M iGPU via Mesa RADV
      models = {
        "qwen2.5-coder-14b" = "unsloth/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M";
        "deepseek-r1-8b" = "unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M";
      };
    };

    services.syncthingSync = {
      enable = true;
      folders = {
        "wallpapers" = {
          id = "wallpapers";
          path = "~/Pictures/wallpapers";
          devices = [
            "apollo"
            "zeus"
            "nixwork"
          ];
        };
      };
    };
  };
}

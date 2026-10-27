{ ... }: {
  flake.nixosModules.sysse-loki-report =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.services.sysadminLokiReport;
      promptFile = pkgs.writeText "sysadmin-loki-prompt.txt" cfg.prompt;

      reportScript = pkgs.writeShellApplication {
        name = "sysadmin-loki-report";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          jq
          libnotify
        ];
        text = ''
          # Ensure ~/.local/bin and /run/current-system/sw/bin are in PATH for `aw` and `pi`
          export PATH="$HOME/.local/bin:/run/current-system/sw/bin:$PATH"

          PROMPT="$(cat ${promptFile})"
          OUTPUT_FILE="${cfg.outputFile}"

          mkdir -p "$(dirname "$OUTPUT_FILE")"

          SUMMARY="$(pi -p --no-session "$PROMPT")"

          {
            echo "# Sysadmin Loki Report — $(date -Iseconds)"
            echo ""
            echo "$SUMMARY"
          } > "$OUTPUT_FILE"

          ${lib.optionalString cfg.notify ''
            notify-send "Sysadmin Loki Report" "Weekly summary saved to $OUTPUT_FILE" || true
          ''}

          ${lib.optionalString (cfg.webhookUrlFile != null) ''
            WEBHOOK_URL="$(cat ${lib.escapeShellArg cfg.webhookUrlFile})"
            curl -fsS -X POST -H 'Content-Type: application/json' \
              -d "$(jq -n --arg text "$SUMMARY" '{text: $text}')" \
              "$WEBHOOK_URL" >/dev/null
          ''}
        '';
      };
    in
    {
      options.services.sysadminLokiReport = {
        enable = lib.mkEnableOption "weekly sysadmin Loki log summary via Pi";

        schedule = lib.mkOption {
          type = lib.types.str;
          default = "Mon *-*-* 08:00:00";
          description = "Systemd OnCalendar schedule.";
        };

        prompt = lib.mkOption {
          type = lib.types.lines;
          default = ''
            Query loki-dev-hz1 (uid: idlqk6HVk) via the grafana MCP server for {owner="sysadmin"} over the last 6h.
            1. Summarize log volume by service (excluding noisy connect-proxy health checks where appropriate).
            2. Highlight notable errors and warnings grouped by service and host.
            Keep the output concise and formatted in Markdown.
          '';
          description = "The prompt passed to `pi -p`.";
        };

        outputFile = lib.mkOption {
          type = lib.types.str;
          default = "$HOME/sysadmin-weekly-report.md";
          description = "Path where the latest Markdown summary is written.";
        };

        notify = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Send a desktop notification when the report finishes.";
        };

        webhookUrlFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/secrets/google-chat-webhook";
          description = "Optional path to a file containing a Google Chat / Slack webhook URL.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.sysadmin-loki-report = {
          description = "Weekly sysadmin Loki log summary via Pi";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe reportScript;
          };
        };

        systemd.user.timers.sysadmin-loki-report = {
          description = "Timer for weekly sysadmin Loki log summary";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.schedule;
            Persistent = true; # Runs immediately on next boot/wake if Monday 08:00 was missed
          };
        };
      };
    };
}

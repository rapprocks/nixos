{ ... }:
{
  flake.nixosModules.security =
    { pkgs, ... }:
    {
      # ──────────────────────────────────────────────────────────────
      # CORE SECURITY
      # ──────────────────────────────────────────────────────────────

      security.polkit.enable = true;
      #security.tpm2.enable = true;

      security.pam.u2f = {
        enable = true;
        settings = {
          cue = true;
          pinverification = 1;
        };
      };

      # Unified GPG Agent configuration for all hosts
      programs.gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-qt;
        enableSSHSupport = true;
      };

      environment.systemPackages = with pkgs; [
        pinentry-qt
        kdePackages.polkit-kde-agent-1
      ];

      systemd.user.services.polkit-kde-agent-1 = {
        description = "polkit-kde-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

    };
}

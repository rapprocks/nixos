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

      services.fprintd.enable = true;

      security.pam.services = {
        login.fprintAuth = false;
      };

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

      services.gnome.gcr-ssh-agent.enable = false;
      programs.zsh.interactiveShellInit = ''
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        export GPG_TTY=$(tty)
      '';

      environment.systemPackages = with pkgs; [
        pinentry-qt
      ];

    };
}

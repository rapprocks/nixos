{ ... }:
{
  flake.nixosModules.shell =
    { pkgs, ... }:
    {

      users.users.earn.shell = pkgs.zsh;

      # ── CORE CLI PACKAGES ──
      environment.systemPackages = with pkgs; [
        wget
        curl
        git
        eza
        fzf
        fd
        tmux
        bat
        tldr
        jq
        ripgrep
        yazi
        htop
        btop
        fastfetch
        screen
        nixd
        typescript
        nodejs
        temporal-cli
        tree
        sops
        opencode
      ];

      services.gnome.gcr-ssh-agent.enable = false;

      # ── SHELL (ZSH + Starship) ──
      programs.zsh = {
        enable = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;
        enableLsColors = true;
        ohMyZsh = {
          enable = true;
          plugins = [ "colored-man-pages" ];
        };
        shellInit = ''export PATH="$HOME/.npm-global/bin:$PATH"'';
        interactiveShellInit = ''
          export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
          export GPG_TTY=$(tty)
        '';
        shellAliases = {
          ip = "ip --color";
          cp = "rsync -ah --progress";
          dot = "cd ~/.dotfiles";
          dev = "cd ~/Development";
          tree = "tree -C";
          weather = "curl -S 'https://wttr.in/Stockholm?1F'";
          cat = "bat --style plain";
          ga = "git add";
          gst = "git status";
          gcm = "git commit -m";
          gpum = "git push -u origin main";
          oc = "opencode";
          ta = "tmux attach";
          vim = "nvim";
          vi = "nvim";
          nsp = "nix-shell -p";
          rb = "sudo nixos-rebuild switch --flake ~/.dotfiles#";
          conf = "~/nixconf";
          ls = "eza --group-directories-first";
          ll = "eza -l --group-directories-first";
          la = "eza -a --group-directories-first";
          lt = "eza --tree --group-directories-first";
          lla = "eza -la --group-directories-first";
          wwup = "sudo wg-quick up ~/work/wg-work.conf";
          wwdown = "sudo wg-quick down ~/work/wg-work.conf";
        };
      };

      programs.starship = {
        enable = true;
        settings = {
          add_newline = false;
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };
        };
      };
    };
}

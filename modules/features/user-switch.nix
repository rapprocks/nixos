{ ... }:
{
  # Switch between logged-in users without logging out, or start a second
  # login on tty2. Only active on hosts with more than one normal user.
  flake.nixosModules.userSwitch =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      normalUsers = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
      enabled = lib.length normalUsers > 1;
      loginVt = 2;
      greeterSock = "/run/greetd-tty2.sock";
      handoffFile = "/run/switch-user/next";

      # tty2 login screen: pre-fills the user that switch-user asked for, if any.
      # The file is removed on read, and only known users are accepted.
      greeterTty2 = pkgs.writeShellApplication {
        name = "greeter-tty2";
        text = ''
          args=()
          if [ -f ${handoffFile} ]; then
            next="$(cat ${handoffFile})"
            rm -f ${handoffFile}
            case "$next" in
              ${lib.concatStringsSep "|" normalUsers}) args=(--user "$next") ;;
            esac
          fi
          exec ${config.services.dm.greetd.greeterCommand} "''${args[@]}"
        '';
      };

      greeterConfig = (pkgs.formats.toml { }).generate "greetd-tty2.toml" {
        terminal = {
          vt = loginVt;
          switch = false;
        };
        default_session = {
          command = "${greeterTty2}/bin/greeter-tty2";
          user = "greeter";
        };
      };

      switch-user = pkgs.writeShellApplication {
        name = "switch-user";
        runtimeInputs = [
          config.systemd.package
          pkgs.procps
          pkgs.gawk
          pkgs.rofi
          pkgs.libnotify
        ];
        text = ''
          me="$(id -un)"
          handoff="${handoffFile}"
          # Users come from the NixOS config, so system accounts (nixbld*) never appear.
          known_users=(${lib.escapeShellArgs normalUsers})

          usage() {
            echo "usage: switch-user [USER | --logout]" >&2
            echo "  no argument: pick a user from a menu" >&2
            exit 1
          }

          is_known() {
            local u
            for u in "''${known_users[@]}"; do
              [ "$u" = "$1" ] && return 0
            done
            return 1
          }

          # Lock the current session before handing the screen over.
          lock_current() {
            if ! pgrep -x hyprlock >/dev/null; then
              hyprlock >/dev/null 2>&1 &
              sleep 0.5
            fi
          }

          # Print the id of user $1's graphical ("user" class) session, if any.
          # Plain output: SESSION UID USER SEAT LEADER CLASS TTY IDLE SINCE.
          find_session() {
            local user="$1"
            loginctl list-sessions --no-legend \
              | awk -v u="$user" '$3 == u && $6 == "user" { print $1; found = 1; exit } END { exit !found }'
          }

          fail() {
            echo "switch-user: $*" >&2
            notify-send "switch-user" "$*" || true
            exit 1
          }

          # The menu: one row per known user, then "Log out".
          # Your own row gets a green marker. The cursor starts on it.
          menu() {
            local rows=() self_idx=0 i=0 u label
            for u in "''${known_users[@]}"; do
              if [ "$u" = "$me" ]; then
                label="<span foreground='#9ccfd8'>●</span> $u"
                self_idx=$i
              else
                label="  $u"
              fi
              if find_session "$u" user >/dev/null; then
                label="$label (logged in)"
              fi
              rows+=("$label")
              i=$((i + 1))
            done
            rows+=("Log out")

            local idx
            idx="$(printf '%s\n' "''${rows[@]}" | rofi -dmenu -markup-rows -no-custom -format i \
              -selected-row "$self_idx" \
              -theme-str 'mainbox { children: [ listview ]; } listview { lines: ${toString (lib.length normalUsers + 1)}; }' \
              || true)"
            [ -n "$idx" ] || exit 0

            if [ "$idx" -ge "''${#known_users[@]}" ]; then
              exec niri msg action quit --skip-confirmation
            fi
            exec "$0" "''${known_users[$idx]}"
          }

          if [ "$#" -gt 1 ]; then
            usage
          fi

          case "''${1:-}" in
            --logout)
              exec niri msg action quit --skip-confirmation
              ;;
            --help|-h)
              usage
              ;;
            "")
              menu
              ;;
          esac

          target="$1"

          if ! is_known "$target"; then
            echo "switch-user: unknown user: $target" >&2
            exit 1
          fi

          if [ "$target" = "$me" ]; then
            lock_current
            exit 0
          fi

          lock_current

          if session="$(find_session "$target" user)"; then
            loginctl activate "$session" || fail "could not activate session for $target"
            else
              # No session yet: tell the tty2 greeter who is signing in, then move
              # the seat there. greetd starts its greeter on that VT.
              printf '%s\n' "$target" > "$handoff"
              busctl call org.freedesktop.login1 /org/freedesktop/login1/seat/seat0 \
                org.freedesktop.login1.Seat SwitchTo u ${toString loginVt} \
                || fail "could not switch to tty${toString loginVt}"
            fi
        '';
      };
    in
    lib.mkIf enabled {
      assertions = [
        {
          assertion = config.services.dm.greetd.enable;
          message = "userSwitch needs services.dm.greetd (displayManager) enabled.";
        }
      ];

      environment.systemPackages = [ switch-user ];

      # Handoff directory for the tty2 greeter. /run is cleared on every boot.
      # World-writable so any logged-in user can write the name, and the
      # greeter can remove the file after reading it.
      systemd.tmpfiles.rules = [ "d /run/switch-user 0777 root root -" ];

      # Polkit: any local active user may switch to another user's session.
      # Locking with hyprlock remains the protection for each session.
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.login1.chvt" &&
              subject.local && subject.active && subject.isInGroup("users")) {
            return polkit.Result.YES;
          }
        });
      '';

      # Second greeter on tty2, same look as tty1. Its own socket keeps it
      # separate from the tty1 greetd instance.
      systemd.services.greetd-tty2 = {
        description = "greetd login screen on tty${toString loginVt}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "systemd-user-sessions.service" ];
        after = [
          "systemd-user-sessions.service"
          "plymouth-quit-wait.service"
        ];
        conflicts = [ "getty@tty${toString loginVt}.service" ];
        environment.GREETD_SOCK = greeterSock;
        serviceConfig = {
          ExecStart = "${config.services.greetd.package}/bin/greetd --config ${greeterConfig}";
          Type = "idle";
          StandardInput = "tty";
          StandardOutput = "tty";
          StandardError = "journal";
          TTYPath = "/dev/tty${toString loginVt}";
          TTYReset = true;
          TTYVHangup = true;
          TTYVTDisallocate = true;
          Restart = "always";
        };
      };

      # Keep the kernel getty off tty2 so only the greeter runs there.
      systemd.services."autovt@tty${toString loginVt}".enable = false;
    };
}

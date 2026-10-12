# Quickshell Integration Plan

Status: **proposal only** — nothing in this document is wired into the live
configuration. All Nix/QML snippets below are illustrative. No file other
than this one was created or modified to produce this plan.

## Context Recap

- Flake uses `flake-parts` + `import-tree ./modules`; every `.nix` file under
  `modules/` is auto-loaded as a flake-parts module and typically exports
  `flake.nixosModules.<name>`. Nothing is auto-enabled — modules must be
  added to an `imports = [ self.nixosModules.<name> ... ]` list at the
  profile or host level.
- Two hosts: `zeus` and `nixwork` (AGENTS.md's "kde" host does not exist;
  trust `modules/hosts/*`). Both currently select `self.nixosModules.slimniri`
  (Niri + Waybar + swaync + hypridle/hyprlock + polkit agent), via
  `modules/hosts/{zeus,nixwork}/configuration.nix`.
- `modules/desktop/niri.nix` owns core Niri enablement + shared desktop
  packages; `modules/desktop/slimniri.nix` owns the Waybar-based session
  layer (status bar, notifications, idle/lock, polkit agent) and is where a
  Quickshell shell would most naturally sit alongside/instead of Waybar.
- `modules/desktop/kdniri.nix` is a second, Waybar-free session
  (`dms-shell`/Plasma) — not a target for this work unless asked.
- No Home Manager anywhere. Per-user config files are delivered by a
  custom activation-script symlink mechanism in
  `modules/features/dotfiles.nix` (`services.dotfiles.mappings` /
  `themedMappings`), pulling from the external `rapprocks/dotfiles` repo.
- No `overlays/` directory, no `nixpkgs.overlays`, no `callPackage`
  infrastructure exists anywhere in this repo today. The only in-repo
  package authoring convention is inline `pkgs.writeShellScriptBin` (see
  `themeSwitcher` in `modules/features/dotfiles.nix`).
- `tests/evaluate.nix` builds a `nixosSystem` per `{zeus,nixwork} x
  {slimniri,kdniri}` combination (no `nixos-rebuild`, no activation) and
  asserts on specific `config.systemd.user.services` / `config.programs.*`
  / `config.services.dotfiles.*` values. This is the repo's sanctioned
  verification surface alongside the two `nix eval`/`nix build` invocations
  named in `AGENTS.md`.
- **Verified during this planning pass:** `quickshell` *is* already
  packaged in current `nixos-unstable` nixpkgs (this flake's `nixpkgs`
  input), at `legacyPackages.x86_64-linux.quickshell`, version `0.3.1`,
  homepage `https://quickshell.org`, license `LGPL-3.0-only`. No extra
  flake input or custom derivation is required to obtain the Quickshell
  binary itself. (Checked live via
  `nix eval github:nixos/nixpkgs/nixos-unstable#legacyPackages.x86_64-linux.quickshell.{version,meta.description,meta.homepage}`
  against the exact `nixos-unstable` ref currently pinned in this flake's
  `flake.lock`.)

---

## 1. Packaging Quickshell Itself

**Recommendation: consume `pkgs.quickshell` directly from the existing
`nixpkgs` input. Do not add a new flake input and do not write a custom
derivation/overlay for the binary.**

Rationale:
- Quickshell is present in `nixos-unstable`, which is exactly the channel
  this flake already pins (`nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"`
  in `flake.nix`). There is zero packaging gap to fill — this is the
  simplest possible case and matches the repo's existing style of plain
  `environment.systemPackages = with pkgs; [ ... ];` lists (see
  `modules/desktop/niri.nix`, `modules/desktop/slimniri.nix`).
- Adding a second flake input (e.g. upstream
  `git+https://git.outfoxxed.me/quickshell/quickshell` flake, which ships
  its own nixpkgs pin and overlay) would introduce a *second* Qt6/nixpkgs
  evaluation closure living alongside this flake's own `nixpkgs` input.
  That doubles build-time Qt6 closures, risks subtle ABI/library mismatches
  between two different nixpkgs revisions' Qt6 stacks, and is unnecessary
  complexity this repo has never needed for any other package. It is only
  justified if nixpkgs' version lags badly behind what's needed, or a
  required Quickshell feature/QML module is missing from nixpkgs' build
  (e.g. a specific compile-time flag). Neither is currently known to be
  true — this plan defers that question explicitly in Rollout §7.
- No `overlays/` convention exists in this repo to extend in the first
  place; introducing one just for a single already-packaged binary would
  be scope creep relative to "packaged and wired the Nix way this repo
  already uses."

**If** nixpkgs' `quickshell` later proves stale or missing a QML module the
chosen shell config needs (common community shells like `caelestia`,
`noctalia`, or `end-4/dots-hyprland`'s quickshell config sometimes track
upstream HEAD), the fallback — *only if actually needed* — is to pin
`pkgs.quickshell` via `nixpkgs.overlays` in a new, narrowly-scoped
`modules/core/overlays.nix` file that overrides just that one derivation
from the upstream quickshell flake input, rather than importing its entire
nixpkgs pin. That is a bigger decision (first overlay in the repo) and
should be raised explicitly rather than assumed; see open question in
§7.

Version/channel considerations:
- Because `quickshell` tracks `nixos-unstable`, routine `nix flake update`
  of the existing `nixpkgs` input will pick up new Quickshell releases
  automatically — no separate input to remember to bump.
- Quickshell's QML API has changed between releases historically (it is a
  young, fast-moving project); pin awareness belongs with whoever owns the
  QML shell config (see §2) — a `flake.lock` bump that changes
  `pkgs.quickshell`'s version should be treated as a potential QML-breaking
  change, similar to how a Waybar bump could break `waybar/config.jsonc`.

---

## 2. Where Quickshell's QML Config Should Live

Two options, evaluated against this repo's existing pattern:

### Option A — QML lives in the external `rapprocks/dotfiles` repo, symlinked by `services.dotfiles` (recommended)

Mirrors exactly how every other piece of session config is already handled
(`niri/config.kdl`, `waybar/*`, `fuzzel/fuzzel.ini`, `alacritty/*`, etc. —
all symlinked from `~/.dotfiles/...` via `modules/features/dotfiles.nix`).

Proposed addition to `services.dotfiles.mappings` (illustrative — actual
edit happens in a later implementation task, not this plan):

```nix
# illustrative only — not applied by this plan
services.dotfiles.mappings."${".config/quickshell"}" = "quickshell";
```

i.e. target `~/.config/quickshell` → source `~/.dotfiles/quickshell`
(Quickshell's default config search path is `$XDG_CONFIG_HOME/quickshell/<name>`
or `QS_CONFIG_PATH`/`qs -c <path>`; either works with a plain directory
symlink the same way Waybar's `~/.config/waybar` works today).

Tradeoffs:
- **Pro:** Zero new infrastructure. Reuses the exact mechanism, ownership
  model (`chown`, `.bak` fallback, theming hooks), and mental model already
  established for every other dotfile in this repo. Editing/iterating on
  QML does not require a Nix rebuild — exactly like Waybar's CSS/JSON
  config today, which is the repo's established UX for "frequently-tweaked
  widget config."
  - Theming: Quickshell shells commonly want a dark/light or
    colorscheme-swap mechanism. `services.dotfiles.themedMappings` already
    exists and is used for Waybar/alacritty/fuzzel/tmux/swaync; a
    Quickshell equivalent (e.g. a themed `colors.qml` or a themed top-level
    shell file) slots into that option with no new code.
- **Con:** QML content is *not* reproducible from this flake alone — same
  limitation that already applies to every other dotfiles-managed config
  in this repo (Niri's own `config.kdl` included), so it is consistent
  with, not worse than, current practice. `nix build`/`nix eval` cannot
  validate QML syntax (same is already true for `config.kdl`, Waybar JSON,
  etc.) — this is an accepted tradeoff this repo already lives with.
- **Con:** Quickshell shell configs are commonly packaged by their authors
  as directories with multiple QML files, imports, assets (SVGs, fonts) —
  needs a `shell.qml` entrypoint at the directory root for `qs` to find
  automatically, which is a convention of the external dotfiles repo to
  get right, not something this flake enforces.

### Option B — QML built into the Nix store as a package in this repo

E.g. `modules/features/quickshell/default.nix` using
`pkgs.stdenvNoCC.mkDerivation` to copy a `shell/` directory of QML files
into `$out/share/quickshell/<name>`, then reference that store path via an
environment variable (`QS_CONFIG_PATH` or `qs -p <store-path>`) or a
wrapper script.

Tradeoffs:
- **Pro:** Fully reproducible/pinned alongside the rest of system config;
  `nix build`/`nix eval` can validate the derivation builds (though not
  that the QML is semantically correct — QML has no static Nix-checkable
  syntax validator available at eval time either way).
- **Con:** Breaks from this repo's established division of labor (Nix
  owns packages/services, `rapprocks/dotfiles` owns config *content*).
  Every other piece of comparable config (Waybar, Niri itself, fuzzel,
  alacritty, rofi, swayosd) lives in dotfiles, not in-repo — making
  Quickshell's QML the one exception would be inconsistent and harder to
  discover/maintain (source-of-truth split across two repos for one vs.
  all-in-dotfiles for everything else).
- **Con:** Iterating on QML (very likely during initial bring-up, given
  Quickshell shells are typically hand-rolled per-user) would require a
  Nix rebuild per change, which is slow compared to dotfiles' instant
  symlink + Quickshell's own live-reload (`qs` supports hot-reloading QML
  files it's watching) — Option A preserves that fast loop, Option B
  defeats it.

**Recommendation: Option A.** Keep the Nix side limited to installing the
`quickshell` package and defining how/when it's launched (systemd user
service + env vars); let `rapprocks/dotfiles` own the actual `shell.qml`
tree, exactly like Waybar's `config.jsonc`/`style.css` today. Only revisit
Option B if there's a concrete need for build-time reproducibility of the
QML itself (not indicated by anything in the recon brief or current repo
conventions).

---

## 3. New Flake Module(s)

Proposed new file: **`modules/features/quickshell.nix`** (single file,
matching the granularity of sibling feature modules like
`modules/features/dotfiles.nix` — no need for a `default.nix` subdirectory
since there's no in-repo QML/package content per Option A above).

Illustrative skeleton (not applied by this plan):

```nix
# modules/features/quickshell.nix — illustrative/proposed only
{ self, ... }:
{
  flake.nixosModules.quickshell =
    { lib, pkgs, config, ... }:
    let
      cfg = config.programs.quickshell;
    in
    {
      options.programs.quickshell = {
        enable = lib.mkEnableOption "Quickshell QML-based Wayland shell";

        configName = lib.mkOption {
          type = lib.types.str;
          default = "default";
          description = ''
            Name of the Quickshell shell config to load, i.e. the
            subdirectory under `~/.config/quickshell/` (or `QS_CONFIG_PATH`)
            containing `shell.qml`. Corresponds to `qs -c <configName>`.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.quickshell;
          description = "Quickshell package to use.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

        systemd.user.services.quickshell = {
          description = "Quickshell";
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          requisite = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe cfg.package} -c ${cfg.configName}";
            Restart = "on-failure";
          };
          wantedBy = [ "niri.service" ];
        };
      };
    };
}
```

This mirrors `modules/desktop/slimniri.nix`'s existing `waybar` systemd
user unit nearly verbatim (`partOf`/`after`/`requisite` on
`graphical-session.target`, `wantedBy = [ "niri.service" ]`,
`Restart = "on-failure"`), which is the established pattern for
session-level daemons in this repo.

### Wiring options (opt-in, not auto-enabled)

Per AGENTS.md's wiring model, exporting `flake.nixosModules.quickshell`
does **not** enable anything by itself. Two concrete wiring choices,
not mutually exclusive:

- **(a) Opt-in per host (recommended for initial rollout):** import
  `self.nixosModules.quickshell` directly in
  `modules/hosts/zeus/configuration.nix`'s `imports` list (alongside
  `self.nixosModules.slimniri`) and set `programs.quickshell.enable = true;`
  there — leaving `nixwork` untouched until proven out. This matches
  AGENTS.md's host-entrypoint pattern exactly and keeps the blast radius to
  one host.
- **(b) Profile-level (future, once proven):** fold the import into
  `modules/desktop/slimniri.nix` itself (since slimniri already owns the
  "status bar" concern via Waybar) behind a module option default of
  `false`, so both `zeus` and `nixwork` gain the *option* but neither is
  forced to enable it. This keeps `slimniri.nix` as the single place that
  owns "what session-level UI daemons run," consistent with how it already
  owns Waybar/swaync/polkit/hypridle.

This plan recommends **starting with (a)**, scoped to `zeus` only, and only
promoting to (b) once the shell config is stable (see §7 Rollout).

### Coexistence with Waybar

Nothing above requires removing Waybar. `programs.quickshell.enable` and
Waybar's existing hardcoded `systemd.user.services.waybar` in
`modules/desktop/slimniri.nix` can run simultaneously for A/B comparison
during bring-up (both are just independent user services keyed off
`graphical-session.target`/`niri.service`). Once Quickshell replaces
Waybar for a given host, Waybar's `environment.systemPackages` entry and
its `systemd.user.services.waybar` block in `slimniri.nix` would need
corresponding removal — call this out as a follow-up decision in §7, not
assumed here.

---

## 4. Niri Integration Specifics

Niri supports a `spawn-at-startup` directive in its own KDL config
(`~/.config/niri/config.kdl`, which — per the recon brief — is itself
sourced from `rapprocks/dotfiles` via the `".config/niri/config.kdl" =
"niri/2027.kdl";` mapping, not built by this flake). There are therefore
two mechanically different ways to launch Quickshell, with different
ownership implications:

| Approach | Where it lives | Pros | Cons |
|---|---|---|---|
| **systemd user service** (recommended, §3 above) | This flake (`modules/features/quickshell.nix`) | Consistent with how Waybar/polkit-agent/kanshi are already started in this repo (all `systemd.user.services.*`, `wantedBy = [ "niri.service" ]`); gives you `systemctl --user status/restart quickshell`, `Restart=on-failure`, standard logs via `journalctl --user -u quickshell`; survives independent of niri config file edits in the external dotfiles repo. | None significant — this is already the repo's pattern. |
| **Niri `spawn-at-startup`** | External dotfiles repo (`niri/2027.kdl`) | Simpler one-liner if someone is already hand-editing `config.kdl`. | Niri's `spawn-at-startup` has no built-in respawn/restart-on-crash semantics (it's fire-once at compositor start) and lives outside this flake's visibility entirely — inconsistent with how every other session daemon (Waybar, kanshi, polkit agent) is already managed as a systemd unit in this repo. Would be the only session daemon *not* represented in Nix, breaking discoverability. |

**Recommendation: use the systemd user service approach from §3**, for
consistency with every existing session daemon in this repo and to keep
Quickshell's lifecycle visible/manageable from the Nix side rather than
buried in an externally-synced KDL file.

### Ordering / conflicts with swayidle, hypridle, greetd

- The recon brief confirms this repo uses **hypridle/hyprlock**, not
  swayidle (AGENTS.md's "swayidle" wording is stale terminology for the
  same functional role) — `services.hypridle.enable = true;` and
  `programs.hyprlock.enable = true;` in `modules/desktop/slimniri.nix`.
  Neither hypridle nor greetd reference Waybar or any status-bar process
  by name or dependency, so adding a `quickshell.service` keyed the same
  way as `waybar.service` (`partOf`/`after`/`requisite` on
  `graphical-session.target`, `wantedBy = [ "niri.service" ]`) introduces
  no new ordering dependency on, or conflict with, hypridle/hyprlock/greetd
  — they are independent units that already coexist with Waybar today
  under the identical target.
- No port/socket/DBus name collision is expected between Quickshell and
  hypridle/hyprlock/greetd (different processes, no shared bus names found
  in the recon brief for any of them, besides the polkit agent's own
  well-known `org.kde.polkit-kde-authentication-agent-1` name which
  Quickshell doesn't touch).
- If Quickshell later takes over lock-screen or idle-inhibit duties (some
  Quickshell community shells implement their own lock screen via
  `ext-session-lock-v1`), that would directly conflict with
  `hyprlock`/`hypridlh` and must be reconciled explicitly — flagged as an
  open question in §7, not assumed here.

---

## 5. Module Structure / Options Design

Concrete option skeleton (expands on §3's illustrative snippet; this is
the full intended surface, not yet written to any file):

```
options.programs.quickshell = {
  enable      :: bool, default false          # master on/off switch
  package     :: package, default pkgs.quickshell
  configName  :: str, default "default"       # -c <name> passed to `qs`
                                               # selects ~/.config/quickshell/<name>/shell.qml
}
```

Per-host overrides follow the pattern already established for other
per-host toggles (e.g. `services.dm.greetd.autoLogin` in
`modules/desktop/display-manager.nix`, set differently per host at the
host-config level): each host's `configuration.nix` sets
`programs.quickshell.enable` (and optionally `configName`, if different
hosts want different widget layouts — e.g. a laptop-specific config on
`nixwork` with battery/brightness widgets vs. a desktop-specific one on
`zeus`) independently, with the module default staying `enable = false`
so adding the module to `workstation.nix`/`slimniri.nix` in the future
(§3 option (b)) does not silently turn it on everywhere.

No `lib.types.enum` is proposed for `configName` (unlike, say,
`defaultTheme` in `dotfiles.nix`, which is a closed `dark`/`light` set) —
`configName` is an open string because it just names a subdirectory under
`~/.config/quickshell/`, whose set of valid values lives in the external
dotfiles repo, not in this flake.

---

## 6. Verification Plan (non-activating only)

Consistent with AGENTS.md's existing sanctioned verification commands —
**no `nixos-rebuild switch` at any point in verification**:

1. **Per-host eval/build**, exactly as AGENTS.md already prescribes, run
   for whichever host(s) gain the module:
   ```sh
   nix eval --raw .#nixosConfigurations.zeus.config.system.build.toplevel.drvPath
   nix build --no-link .#nixosConfigurations.zeus.config.system.build.toplevel
   ```
   (swap `zeus` → `nixwork` once/if wired there too). A successful build
   here validates the new module's Nix evaluates and that
   `pkgs.quickshell` fetches/builds (or substitutes) cleanly as part of
   `environment.systemPackages` — it does **not** validate QML content,
   matching the repo's existing stance that a system build doesn't verify
   externally-sourced config content (per AGENTS.md's note that "a
   successful system build does not verify host decryption," same
   epistemic status applies here for dotfiles-sourced QML).

2. **Full matrix eval**, per AGENTS.md:
   ```sh
   nix eval --impure --option allow-import-from-derivation false --json \
     --file tests/evaluate.nix
   ```
   using a `path:` flake ref if iterating on untracked changes, as
   AGENTS.md recommends.

3. **Extend `tests/evaluate.nix`** once the module lands, to keep the
   matrix exhaustive (illustrative diff, not applied by this plan):
   - If wiring is host-opt-in only (§3 option (a), the recommended start),
     no new `genAttrs` dimension is strictly required — instead add an
     assertion gated on host identity, e.g.:
     ```nix
     # illustrative only
     assert (host == "zeus") -> (builtins.hasAttr "quickshell" config.systemd.user.services);
     assert (host == "nixwork") -> !(builtins.hasAttr "quickshell" config.systemd.user.services);
     ```
   - If/when promoted to profile-level opt-in (§3 option (b), a new
     per-session toggle), extend the existing
     `lib.genAttrs [ "slimniri" "kdniri" ]` session matrix with the new
     enable flag, mirroring the existing
     `assert (builtins.hasAttr "waybar" config.systemd.user.services) == (session == "slimniri");`
     pattern already present in the file, e.g.:
     ```nix
     # illustrative only
     assert (builtins.hasAttr "quickshell" config.systemd.user.services) == cfg.enable;
     ```
   - Either way, **do not** invent a third session name
     (`"quickshell-niri"` or similar) in the `genAttrs` matrix unless
     Quickshell becomes a true alternative *session* module analogous to
     `slimniri`/`kdniri` rather than an additive daemon — that would be a
     bigger scope change than this plan proposes and should go back to the
     user as a decision point if it comes up.

4. No new test *file* is proposed — `tests/evaluate.nix` is the sole
   evaluation-matrix file in this repo and the natural extension point per
   the recon brief; adding a parallel test file would fragment the single
   source of truth AGENTS.md already documents.

---

## 7. Rollout Plan

Suggested order of work for a follow-up implementation task:

1. **Module skeleton**: add `modules/features/quickshell.nix` per §3,
   wired only into `modules/hosts/zeus/configuration.nix` with
   `programs.quickshell.enable = true;` (§3 option (a)). Leave `nixwork`
   untouched.
2. **Eval/build check**: run the two `nix build`/`nix eval` commands from
   §6 step 1 against `zeus` to confirm the module evaluates and
   `pkgs.quickshell` builds/substitutes.
3. **Dotfiles mapping**: add the `.config/quickshell` mapping (§2, Option
   A) to `modules/features/dotfiles.nix`'s `services.dotfiles.mappings`,
   and coordinate with the external `rapprocks/dotfiles` repo to add a
   minimal `quickshell/shell.qml` (even a placeholder bar) there — this
   half of the work happens outside this flake's tracked files.
4. **Full matrix eval**: run `tests/evaluate.nix` (§6 step 2) and extend it
   per §6 step 3 with the host-gated assertion.
5. **Manual smoke test on `zeus` only**, performed by the user outside of
   this plan's scope (this plan explicitly excludes proposing
   `nixos-rebuild switch` as a verification step; any real-session
   check is the user's call, not part of the eval/build verification
   contract above).
6. **Decide Waybar's fate on `zeus`**: once Quickshell is confirmed
   working, explicitly decide (not assumed by this plan) whether to retire
   Waybar on `zeus` (removing its package + systemd unit from whatever
   module ends up applying to `zeus`) or keep both side-by-side
   permanently.
7. **Promote to `nixwork`** and/or to profile-level (§3 option (b)) only
   after `zeus` is stable, by flipping the per-host `enable` or moving the
   import+default into `modules/desktop/slimniri.nix`.

### Open Questions / Risks to Flag Back to the User

- **No Home Manager**: Quickshell's own ecosystem/community configs
  (several published "quickshell shells" on GitHub) are often documented
  assuming Home Manager's `xdg.configFile` or a HM module. This repo has
  none, by design (per recon brief) — Option A (§2) accommodates this via
  the existing dotfiles symlink mechanism, but it means any
  community-shared Quickshell config will need manual adaptation (strip
  any Home Manager-specific pieces, drop its files into
  `rapprocks/dotfiles/quickshell/`) rather than a drop-in import. Confirm
  this adaptation effort is acceptable before committing to a specific
  community shell config.
- **QML in-repo vs. external dotfiles (§2)**: this plan recommends keeping
  QML entirely in `rapprocks/dotfiles` for consistency with existing
  config (Waybar, Niri, etc.). If reproducibility of the shell UI itself
  becomes a priority (e.g. wanting `nix build` to fully pin the widget
  code, or wanting the QML versioned in the same repo/PR as the systemd
  unit that launches it), that is a deliberate departure from this repo's
  established pattern and should be confirmed explicitly, not inferred.
- **Multi-monitor / Niri-specific QML**: Quickshell shells that implement
  a status bar typically need per-output (per-monitor) bar instances,
  commonly driven by Quickshell's own Wayland output model (`Quickshell.Wayland`
  QML module) rather than anything Nix-side. This plan does not attempt to
  pre-specify multi-monitor QML structure — that is shell-config content
  (§2 Option A), to be designed in the external dotfiles repo, not in this
  flake. Flagging so it isn't silently dropped.
- **Nixpkgs `quickshell` version drift**: confirmed present today at
  `0.3.1` in `nixos-unstable` (see verification note above), but Quickshell
  is an actively evolving project; a later `nix flake update` bumping
  nixpkgs could bump Quickshell's QML API in ways that break a
  previously-working `shell.qml`. No action proposed now beyond noting it
  as an ongoing maintenance consideration once this is live (same
  class of risk as Waybar config vs. Waybar version today, which this repo
  already tolerates).
- **Fallback custom-overlay path (§1)**: only needed if nixpkgs'
  `quickshell` proves insufficient (missing a needed QML submodule/feature
  or lagging upstream too far). This would be the repo's *first* overlay
  and first `nixpkgs.overlays` usage — a real architectural first, not a
  routine addition — and should be brought back as an explicit decision
  if/when it's actually needed, not pre-built speculatively here.
- **Waybar retirement timing (§7 step 6)**: whether/when to remove Waybar
  from `slimniri.nix` once Quickshell is adopted is a product decision
  (do you want both status bars, or a clean replacement?) left
  unresolved by this plan on purpose.

---

## Summary of Recommendations

1. Package: use `pkgs.quickshell` directly from the existing `nixpkgs`
   input (already present in `nixos-unstable`); no new flake input, no
   overlay, unless a concrete gap surfaces later.
2. Config content: keep QML in the external `rapprocks/dotfiles` repo,
   symlinked via `services.dotfiles.mappings` (and `themedMappings` for
   theming), exactly like every other session config in this repo.
3. New module: `modules/features/quickshell.nix` exporting
   `flake.nixosModules.quickshell`, with `programs.quickshell.{enable,
   package, configName}` options and a `systemd.user.services.quickshell`
   unit modeled directly on the existing `waybar` unit in
   `modules/desktop/slimniri.nix`.
4. Niri integration: systemd user service keyed on
   `graphical-session.target`/`niri.service` (not Niri's
   `spawn-at-startup`), coexisting cleanly with existing
   hypridle/hyprlock/greetd/swaync/polkit-agent units.
5. Wiring: opt-in at the `zeus` host level first
   (`modules/hosts/zeus/configuration.nix`), promote to
   `modules/desktop/slimniri.nix`/`nixwork` only after validation.
6. Verification: the two `nix build`/`nix eval` commands from AGENTS.md
   plus an extended `tests/evaluate.nix` assertion — no
   `nixos-rebuild switch` anywhere in the verification loop.
7. Rollout: module skeleton → eval/build → dotfiles mapping →
   full-matrix eval → manual smoke test (user's call) → decide Waybar's
   fate → promote to second host/profile level.

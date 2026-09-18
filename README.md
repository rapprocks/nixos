# NixOS Configuration

Both `kde` and `zeus` currently use the `slimniri` session and Firefox.
The `kdniri` KDE/DMS session and LibreWolf remain selectable alternatives.

## Structure And Ownership

`flake.nix` passes `import-tree ./modules` to flake-parts. Files under
`modules/` are outer flake modules exporting inner `nixosModules`, not bare
NixOS modules. Exporting a module does not enable it; hosts and profiles
select modules through `self.nixosModules`.

```text
modules/
  hosts/{kde,zeus}/
    configuration.nix       Host registration, selections, identity and exceptions
    hardware.nix            Machine-specific hardware and storage
  profiles/workstation.nix  Shared composition, applications, fonts and graphics
  core/
    system.nix              Locale, Nix policy, account, NetworkManager and SSH
    security.nix            Fingerprint/U2F and GPG-backed SSH integration
    sops.nix                Secret-decryption infrastructure
  cli/environment.nix      Shell, CLI/development tools, editor and CLI mappings
  desktop/
    niri.nix                Shared compositor, portals, visual integration and mappings
    slimniri.nix            Sysc-greet, Waybar, notifications, idle and Polkit agent
    kdniri.nix              DMS greeter/shell and Plasma integration
    pipewire.nix            Audio and its supporting configuration
  apps/browsers.nix         Firefox/LibreWolf policies and desktop defaults
  features/
    dotfiles.nix            Checkout, symlink activation and theme switching
    syncthing.nix           Sync service, device inventory and service secrets
    nas-mounts.nix          NAS shares and mount policy
  parts.nix                Flake systems declaration
tests/evaluate.nix         Evaluation matrix for maintained combinations
```

A feature owns its packages, services, dotfile mappings and integration settings.
Do not create a separate global package list or one file per setting. Hosts own
genuine differences: boot policy, `system.stateVersion`, hardware tuning, Wi-Fi
provisioning, Syncthing folders and extra mappings.

`workstation` imports the dotfiles and SOPS infrastructure once. CLI and desktop
modules contribute mappings; Syncthing contributes its secret declaration. These
modules are intended to be composed with `workstation`, not imported as standalone
systems. Do not repeat infrastructure imports through several anonymous exported
modules, as that can duplicate option declarations.

## Selecting Alternatives

In a host's `imports`, replace `slimniri` with `kdniri`, or `firefox` with
`librewolf`. Select exactly one session and one browser. Both browser variants
configure `programs.firefox`; LibreWolf substitutes its package and policy path.
Each variant owns its `BROWSER` variable and browser/PDF MIME defaults.

`kdniri` does not inherit Slim's Waybar or swaync. SwayOSD and swaylock remain in
the shared Niri module because the current external Niri config invokes them.
Plasma/DMS provide the alternative desktop's authentication integration; Slim
starts its KDE Polkit agent explicitly.

## External Configuration

- Application dotfiles live in `rapprocks/dotfiles`. Mappings use home-relative
  destinations and paths relative to `~/.dotfiles` for sources.
- Dotfiles activation clones only when absent, never pulls, and backs up
  conflicting non-symlink paths to `.bak`. Evaluation does not run activation.
- Neovim is supplied by the `rapprocks/nixvim` flake and installed by the CLI module.
- Secrets stay encrypted in `secrets/secrets.yaml` and must be edited with SOPS.
  Runtime decryption uses `/etc/ssh/ssh_host_ed25519_key`.

The existing external Niri config starts Kanshi and hardcodes commands including
`firefox` and the swaylock configuration path. Selecting LibreWolf changes NixOS
defaults, not those external keybindings. Update that repository separately when
changing its behavior. Host-specific Waybar mappings, Syncthing topology, and the
current idle/sleep behavior are preserved by this reorganization.

## Evaluation Only

From the repository root:

```sh
nix eval --option allow-import-from-derivation false --raw .#nixosConfigurations.zeus.config.system.build.toplevel.drvPath
nix eval --option allow-import-from-derivation false --raw .#nixosConfigurations.kde.config.system.build.toplevel.drvPath
nix eval --impure --option allow-import-from-derivation false --json --file tests/evaluate.nix
```

The matrix evaluates both hosts with both sessions and browsers, checks selection
invariants, and verifies that the active combination matches each real host.
These commands do not build or activate systems. Disabling import-from-derivation
also prevents evaluation from triggering builds.

While new files are still untracked, use `path:$PWD#...` instead of `.#...` for
the first two commands. The matrix already uses a path flake so it includes new
files without staging them. There is no configured formatter or development shell.

Evaluation cannot verify runtime secret decryption, external dotfile contents,
or graphical-session behavior. Activation is a separate, explicitly requested step.

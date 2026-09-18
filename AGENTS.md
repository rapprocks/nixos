# Repository Guidance

## Module Wiring
- `flake.nix` feeds `import-tree ./modules` into `flake-parts`. Files under `modules/` are flake modules, usually exporting `flake.nixosModules.<name>`, not bare NixOS modules. Follow this outer/inner module pattern when adding files.
- Exporting a NixOS module does not enable it: wire it into a profile or host through `self.nixosModules`. Host entrypoints are `modules/hosts/{kde,zeus}/configuration.nix`; shared imports live in `modules/profiles/workstation.nix`.
- Both hosts currently select `slimniri` (Niri, swayidle, greetd), including the host named `kde`. Trust active imports over the README's profile list and TODOs.

## Verification And Activation
Run from the repository root; replace `zeus` with `kde` for the other host. Check both when changing shared modules.

```sh
# Evaluate the system derivation without building or activating it.
nix eval --raw .#nixosConfigurations.zeus.config.system.build.toplevel.drvPath
# Build the system without activation or a result symlink.
nix build --no-link .#nixosConfigurations.zeus.config.system.build.toplevel
```

- Evaluate all maintained host/session/browser combinations with `nix eval --impure --option allow-import-from-derivation false --json --file tests/evaluate.nix`. Use a `path:` flake reference to include untracked modules without staging. There is no CI, formatter output, or dev shell; do not assume `nix fmt` or `nix develop` is configured.
- Activate only when requested, on the intended machine: `sudo nixos-rebuild switch --flake .#zeus` (or `.#kde`). The `rb` alias in `modules/cli/environment.nix` instead assumes `~/nixconf` and implicit hostname selection; avoid it for explicit verification.

## External Configuration And Secrets
- Both hosts use `rapprocks/dotfiles` via `services.dotfiles`. Host mappings point from paths relative to the user's home to paths relative to `~/.dotfiles`; application config contents generally belong in that external repository.
- `modules/features/dotfiles.nix` clones the repository only when absent, never pulls on rebuild, and creates symlinks during activation, moving conflicting non-symlink paths to `.bak`. Activation is not a read-only validation step.
- Neovim comes from the external `rapprocks/nixvim` flake input and is installed by the shared CLI module; its editor configuration is not defined here.
- Edit `secrets/secrets.yaml` through SOPS, preserving encryption; `.sops.yaml` defines recipients. `modules/core/sops.nix` uses `/etc/ssh/ssh_host_ed25519_key` for runtime decryption with key generation disabled. A successful system build does not verify host decryption.

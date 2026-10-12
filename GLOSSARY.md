# nixconf

NixOS configuration for a small set of personal and work machines, shared through one flake.

## Language

### Machines

**Host**:
A single machine with its own NixOS configuration.
_Avoid_: Machine, box, system

**Profile**:
A bundle of configuration describing what kind of host something is, independent of who uses it.
_Avoid_: Role, preset

### People

**User**:
A person with a login account on a host.
_Avoid_: Account, owner

**Primary user**:
The user present on every host by default; currently `earn`.
_Avoid_: Main user, default user, owner

**Additional user**:
A user added to a specific host on top of the primary user; currently `philip`.
_Avoid_: Second user, guest, secondary user

**Signed-in user**:
The user whose session is currently active on a host; per-user services run as this user.
_Avoid_: Current user, active user, owner

### Dotfiles

**Shared dotfiles**:
Configuration from the dotfiles repository that every user on a host receives.
_Avoid_: Common config, global dotfiles

**Host-specific dotfiles**:
Configuration from the dotfiles repository that every user on one particular host receives.
_Avoid_: Host overrides

**User-specific dotfiles**:
Configuration from the dotfiles repository that only one user receives.
_Avoid_: Personal overrides, per-user extras, exclusions

**Dotfiles clone**:
A user's own copy of the shared dotfiles repository, living in that user's home.
_Avoid_: Shared checkout

{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  cfg = config.profiles.virtualization;
in
{
  options.profiles.virtualization.enable = lib.mkEnableOption "libvirt/QEMU virtualization with virt-manager";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
      OVMF
      swtpm
    ];

    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    users.users.${username}.extraGroups = [
      "libvirtd"
      "kvm"
    ];

    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}


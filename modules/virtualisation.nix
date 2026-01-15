{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profiles.virtualization;
in {
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

    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
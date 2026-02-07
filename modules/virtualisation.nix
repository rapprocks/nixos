{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  cfg = config.profiles.virtualization;
  dockerCfg = config.profiles.docker;
in
{
  options.profiles.virtualization.enable = lib.mkEnableOption "libvirt/QEMU virtualization with virt-manager";
  options.profiles.docker.enable = lib.mkEnableOption "Docker container runtime";

  config = lib.mkMerge [
    # ── libvirt / QEMU ──
    (lib.mkIf cfg.enable {
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
    })

    # ── Docker ──
    (lib.mkIf dockerCfg.enable {
      virtualisation.docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      # Add your user to the docker group so you can run docker without sudo
      users.users.${username}.extraGroups = [ "docker" ];

      # Useful CLI tools for working with containers
      environment.systemPackages = with pkgs; [
        docker-compose
      ];
    })
  ];
}

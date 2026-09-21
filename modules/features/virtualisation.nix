{ ... }:
{
  flake.nixosModules.virtualisation =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.services.virtualisation;
      dockerCfg = config.services.docker;
    in
    {
      options.services.virtualisation.enable = lib.mkEnableOption "libvirt/QEMU virtualisation with virt-manager";
      options.services.docker.enable = lib.mkEnableOption "Docker container runtime";

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

          users.users.earn.extraGroups = [
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
          users.users.earn.extraGroups = [ "docker" ];

          # Useful CLI tools for working with containers
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
        })
      ];
    };
}

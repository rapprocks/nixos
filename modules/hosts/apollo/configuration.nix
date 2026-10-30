{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.apollo = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.apolloConfig ];
  };

  flake.nixosModules.apolloConfig = { ... }: {
    imports = [
      self.nixosModules.apolloHardware
      self.nixosModules.workstation
      self.nixosModules.personal
      self.nixosModules.slimniri
      self.nixosModules.firefox
      self.nixosModules.network
    ]
    ++ [
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-pc-ssd
      inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
      inputs.nixos-hardware.nixosModules.common-gpu-amd
    ];

    programs.steam.enable = true;

    preferences.host.name = "apollo";
    system.stateVersion = "26.05";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    services.agentic = {
      enable = true;
      acceleration = "rocm";
      gfxVersion = "10.3.0";
      models = {
        "qwen2.5-coder-14b" = "unsloth/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M";
        "deepseek-r1-8b" = "unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M";
      };
    };

    services.syncthingSync = {
      enable = true;
      folders = {
        "notes" = {
          id = "notes";
          path = "~/Documents/notes";
          devices = [
            "zeus"
            "truenas"
          ];
        };
        "wallpapers" = {
          id = "wallpapers";
          path = "~/Pictures/wallpapers";
          devices = [
            "zeus"
            "truenas"
            "nixwork"
          ];
        };
      };
    };
  };
}

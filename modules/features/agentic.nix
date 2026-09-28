{ ... }:
{
  flake.nixosModules.agentic =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.services.agentic;

      # Standard Nix conditional logic for package selection
      ollamaPackage =
        if cfg.acceleration == "rocm" then
          pkgs.ollama-rocm
        else if cfg.acceleration == "cuda" then
          pkgs.ollama-cuda
        else if cfg.acceleration == "vulkan" then
          pkgs.ollama-vulkan
        else
          pkgs.ollama-cpu;
    in
    {
      options.services.agentic = {
        enable = lib.mkEnableOption "Agentic workflow stack (Ollama + OpenCode)";

        acceleration = lib.mkOption {
          type = lib.types.enum [
            "none"
            "rocm"
            "cuda"
            "vulkan"
          ];
          default = "none";
          description = ''
            Hardware acceleration mechanism for Ollama.
            Selects the appropriate pkgs.ollama package variant under NixOS unstable.
          '';
        };

        gfxVersion = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "11.0.0";
          description = ''
            ROCm's HSA_OVERRIDE_GFX_VERSION string. 
            Crucial for newer AMD APUs like Ryzen AI 9 HX 370 (Radeon 890M / RDNA3.5).
          '';
        };

        models = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "qwen2.5-coder:7b" ];
          example = [
            "qwen2.5-coder:7b"
            "qwen2.5-coder:14b"
            "deepseek-r1:14b"
          ];
          description = "List of local Ollama models to ensure are downloaded and ready for agents.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.opencode;
          description = "The OpenCode package to install.";
        };
      };

      config = lib.mkIf cfg.enable {
        # 1. Configure Hardware Graphics acceleration conditionally
        hardware.graphics = lib.mkIf (cfg.acceleration != "none") {
          enable = true;
          enable32Bit = true;
        };

        # 2. Configure Ollama natively
        services.ollama = {
          enable = true;
          package = ollamaPackage;
          loadModels = cfg.models;
          rocmOverrideGfx = lib.mkIf (cfg.acceleration == "rocm" && cfg.gfxVersion != null) cfg.gfxVersion;
          modelsDir = "/var/lib/ollama/models"; # Explicitly set model store
        };

        # Export OLLAMA_MODELS system-wide so user CLI reads from system service folder
        environment.variables = {
          OLLAMA_MODELS = "/var/lib/ollama/models";
        };

        # Fix permissions so normal users can list/read models in /var/lib/ollama/models
        system.activationScripts.fixOllamaPermissions = ''
          chmod 755 /var/lib/ollama
          chmod -R 755 /var/lib/ollama/models
        '';

        # 3. Expose CLI tooling system-wide
        environment.systemPackages = [
          cfg.package
          ollamaPackage
          pkgs.gh
        ]
        ++ lib.optionals (cfg.acceleration == "rocm") [
          pkgs.rocmPackages.rocminfo
        ];
      };
    };
}

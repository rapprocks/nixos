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

      llamaPackage =
        if cfg.acceleration == "rocm" then
          pkgs.llama-cpp-rocm
        else if cfg.acceleration == "cuda" then
          pkgs.llama-cpp-cuda
        else if cfg.acceleration == "vulkan" then
          pkgs.llama-cpp-vulkan
        else
          pkgs.llama-cpp;

      # Router-mode preset: one INI section per model name, with the Hugging Face
      # GGUF spec ("repo:quant") as `hf-repo`.
      modelsPreset = (pkgs.formats.ini { }).generate "llama-models-preset.ini" (
        lib.mapAttrs (_: spec: { "hf-repo" = spec; }) cfg.models
      );
    in
    {
      options.services.agentic = {
        enable = lib.mkEnableOption "Agentic workflow stack (llama.cpp + OpenCode)";

        acceleration = lib.mkOption {
          type = lib.types.enum [
            "none"
            "rocm"
            "cuda"
            "vulkan"
          ];
          default = "none";
          description = ''
            Hardware acceleration backend for llama.cpp.
            Selects the matching pkgs.llama-cpp* package variant.
          '';
        };

        gfxVersion = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "11.0.0";
          description = ''
            ROCm's HSA_OVERRIDE_GFX_VERSION string. Only used when acceleration = "rocm".
          '';
        };

        models = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            "qwen2.5-coder-14b" = "unsloth/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M";
            "deepseek-r1-8b" = "unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M";
          };
          description = ''
            Models served by llama-server in router mode, keyed by the name clients request.
            Values are Hugging Face GGUF specs (`repo[:quant]`), downloaded on first use
            into /var/cache/llama-cpp and loaded on demand.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.opencode;
          description = "The OpenCode package to install.";
        };
      };

      config = lib.mkIf cfg.enable {
        # 1. Configure hardware graphics (Mesa/Vulkan ICDs, ROCm runtime hooks)
        hardware.graphics = lib.mkIf (cfg.acceleration != "none") {
          enable = true;
          enable32Bit = true;
        };

        # 2. Configure llama.cpp server in router mode
        services.llama-cpp = {
          enable = true;
          package = llamaPackage;
          settings = {
            models-preset = toString modelsPreset;
            ctx-size = 32768;
            jinja = true;
          };
        };

        systemd.services.llama-cpp = {
          # The upstream unit runs with DynamicUser and no device groups; GPU
          # device nodes (/dev/kfd, /dev/dri/renderD*) are group render/video.
          serviceConfig.SupplementaryGroups = lib.mkIf (cfg.acceleration != "none") [
            "render"
            "video"
          ];

          environment = lib.mkIf (cfg.acceleration == "rocm" && cfg.gfxVersion != null) {
            HSA_OVERRIDE_GFX_VERSION = cfg.gfxVersion;
          };
        };

        # 3. Expose CLI tooling system-wide
        environment.systemPackages = [
          cfg.package
          llamaPackage
          pkgs.gh
        ]
        ++ lib.optionals (cfg.acceleration == "rocm") [
          pkgs.rocmPackages.rocminfo
        ];
      };
    };
}

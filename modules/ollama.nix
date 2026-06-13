{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.profiles.ollama;
in
{
  options.profiles.ollama = {
    enable = lib.mkEnableOption "Enable Ollama";
    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "dolphin3"
        "gemma3"
        "gemma3:27b"
        "deepseek-r1:latest"
        "deepseek-r1:1.5b"

      ];
      description = "List of models to load";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;

      # Enable hardware acceleration based on your GPU
      # acceleration = "cuda"; # Uncomment for modern NVIDIA GPUs
      # acceleration = "rocm"; # Uncomment for modern AMD GPUs

      # Optional: Automatically pull and load specific models when the service starts
      loadModels = cfg.models;
    };

    # Ensure the Ollama CLI is installed so you can run `ollama run ...`
    environment.systemPackages = with pkgs; [
      ollama
    ];
  };
}

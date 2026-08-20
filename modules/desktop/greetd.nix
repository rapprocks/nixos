{ inputs, ... }: {
  flake.nixosModules.greetd = { ... }: {
    imports = [
      inputs.sysc-greet.nixosModules.default
    ];
    services.sysc-greet = {
      enable = true;
      compositor = "niri"; # or "cagebreak", "sway", "hyprland" (deprecated)
    };

    # Optional: Set initial session for auto-login
    #services.sysc-greet.settings.initial_session = {
    #  command = "Hyprland";
    #  user = "your-username";
    #};
  };
}

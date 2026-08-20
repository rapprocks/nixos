{ ... }: {
  flake.nixosModules.dms = { ... }: {
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri";
    };
    programs.dms-shell = {
      enable = true;
      enableCalendarEvents = false;
      enableAudioWavelength = false;
      enableDynamicTheming = false;
      enableSystemMonitoring = false;
    };
  };
}

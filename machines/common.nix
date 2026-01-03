{pkgs, ...}: {
  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "se";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "sv-latin1";

  environment.systemPackages = with pkgs; [
    ueberzugpp
    mpv
    feh
    bluetui
    obsidian
    stow
  ];
}

{ ... }: {
  flake.nixosModules.fonts =
    { pkgs, ... }:
    {
      # Install the font system-wide
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
    };
}

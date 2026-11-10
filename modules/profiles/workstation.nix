{ self, ... }: {
  flake.nixosModules.workstation = { config, lib, pkgs, ... }: {
    imports = with self.nixosModules; [
      preferences
      system
      userEarn
      security
      pipewire
      sops
      cli
      dotfiles
      desktopApps
      displayManager
      syncthing
      virtualisation
      agentic
      fonts
      userSwitch
    ];

    services.dotfiles = {
      enable = true;
      repo = "https://github.com/rapprocks/dotfiles.git";
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.bluetooth = {
      enable = true;
      settings.General.Enable = "Source,Sink,Media,Socket";
    };

    # Shared directory (/mnt/drop) with per-user bindfs mounts at ~/drop
    users.groups.drop = { };
    environment.systemPackages = with pkgs; [
      bindfs
      rbw
      rofi-rbw-wayland
      mpv
      imv
      brave
      (chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--disable-background-timer-throttling"
          "--disable-renderer-backgrounding"
          "--disable-backgrounding-occluded-windows"
          "--disable-features=IntensiveWakeUpThrottling,NotificationPortal"
        ];
      })
      obsidian
      kdePackages.krdc
      bluetui # DECIDE WHICH ONE I WANT TO USE
      cameractrls-gtk4
      #kdePackages.bluedevil
      #kdePackages.bluez-qt
    ];

    systemd.tmpfiles.rules =
      [
        # Type  Path            Mode User  Group       Age Argument
        "d      /mnt/drop       2770 root  drop        -   -"
      ]
      ++ map (
        u: "d ${config.users.users.${u}.home}/drop 0750 ${u} users - -"
      ) config.preferences.user.allUsers;

    fileSystems = lib.listToAttrs (
      map (u: {
        name = "${config.users.users.${u}.home}/drop";
        value = {
          device = "/mnt/drop";
          fsType = "fuse.bindfs";
          options = [
            "force-user=${u}"
            "force-group=users"
            "create-for-user=root"
            "create-for-group=drop"
            "create-with-perms=0660:a+X"
            "perms=0660:a+X"
            "nofail"
          ];
        };
      }) config.preferences.user.allUsers
    );

    xdg.mime.enable = true;
    xdg.mime.defaultApplications = {
      "image/jpeg" = [ "imv.desktop" ];
      "image/jpg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/mkv" = [ "mpv.desktop" ];
    };
  };
}

{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sshSwitch" (builtins.readFile ../../scripts/sshSwitch.sh))
  ];

  services.automatic-timezoned.enable = true;

  networking.hostName = "nixwrk";
  networking.firewall.allowedTCPPorts = [
    32320
    # 5500 # USED TO TEST TOUCHPAD ON GOOGLE MEET CTP
  ]; # TEMP TO RUN OTA FLASH FOR ESP OVER VLAN 50

  programs.zsh.shellInit = ''eval "$(aw autocomplete:script zsh)"'';
  programs.ssh.extraConfig = ''
        	Host tolerant-backup-2
          	HostName tolerant-backup-2.akind.tech
            User root
            Port 2222
            IdentityFile ~/.ssh/id_ed25519_sk_rk
    			Host docker-0-lab
          	HostName 192.168.241.18
            User awadmin
            IdentityFile ~/.ssh/id_ed25519_sk_rk

  '';

  boot.initrd.luks.devices."luks-59f0c2b6-2617-42dc-884a-35acdd0c44c6".device =
    "/dev/disk/by-uuid/59f0c2b6-2617-42dc-884a-35acdd0c44c6";

  profiles = {
    displayManager.autoLogin = true;
    laptop.enable = true;
    virtualization.enable = true;
    ollama = {
      enable = true;
      models = [ "deepseek-r1:1.5b" ];
    };
    docker.enable = true;
    intelGpu = {
      enable = true;
      forceProbe = "46a8";
    };
    security = {
      yubikey.enable = true;
      fingerprint.enable = true;
    };
  };

  system.stateVersion = "25.11";
}

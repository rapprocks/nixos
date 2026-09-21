{ ... }:
{
  flake.nixosModules.work = { ... }: {
    # Add work-only Wi-Fi network to the catalog
    networking.wifiNetworks.work = {
      ssid = "AW-BYOD";
      secretName = "wifi_work";
      #security.keyMgmt = "sae";
    };

    # TODO: Add work-specific settings here as needed (VPN client, corporate certs, work browser profile, etc.)
  };
}

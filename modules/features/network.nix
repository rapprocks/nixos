{ ... }:
{
  flake.nixosModules.network =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.networking.wifiConfig;
    in
    {
      options.networking.wifiNetworks = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              ssid = lib.mkOption {
                type = lib.types.str;
                description = "The SSID of the Wi-Fi network.";
              };
              secretName = lib.mkOption {
                type = lib.types.str;
                description = "The SOPS secret name for the Wi-Fi password (without 'wifi_' prefix).";
              };
            };
          }
        );
        default = {
          k69 = {
            ssid = "k69";
            secretName = "wifi_k69";
          };
        };
        description = "Catalog of known Wi-Fi networks with their SSID and SOPS secret names.";
      };

      options.networking.enabledWifiNetworks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of Wi-Fi network names (keys from wifiNetworks) to enable on this host.";
      };

      config = lib.mkIf (config.networking.enabledWifiNetworks != []) {
        # Only enable iwd and NetworkManager Wi-Fi backend if at least one network is enabled
        networking.wireless.iwd.enable = true;
        networking.networkmanager.wifi.backend = "iwd";

        # Generate sops secrets and NetworkManager profiles for each enabled network
        sops.secrets = lib.mapAttrs' (
          name: network:
          lib.nameValuePair
            network.secretName
            { }
        ) (lib.filterAttrs (name: _: lib.elem name config.networking.enabledWifiNetworks) config.networking.wifiNetworks);

        sops.templates = lib.mapAttrs' (
          name: network:
          lib.nameValuePair
            "wifi-${name}.env"
            {
              content = ''${lib.toUpper network.secretName}=${config.sops.placeholder.${network.secretName}}'';
            }
        ) (lib.filterAttrs (name: _: lib.elem name config.networking.enabledWifiNetworks) config.networking.wifiNetworks);

        networking.networkmanager.ensureProfiles = {
          environmentFiles = lib.mapAttrsToList (
            name: _: config.sops.templates."wifi-${name}.env".path
          ) (lib.filterAttrs (name: _: lib.elem name config.networking.enabledWifiNetworks) config.networking.wifiNetworks);
          profiles = lib.mapAttrs' (
            name: network:
            lib.nameValuePair
              name
              {
                connection = {
                  id = name;
                  type = "wifi";
                };
                wifi = {
                  mode = "infrastructure";
                  ssid = network.ssid;
                };
                wifi-security = {
                  key-mgmt = "wpa-psk";
                  psk = "$${lib.toUpper network.secretName}";
                };
                ipv4.method = "auto";
                ipv6.method = "auto";
              }
          ) (lib.filterAttrs (name: _: lib.elem name config.networking.enabledWifiNetworks) config.networking.wifiNetworks);
        };
      };
    };
}

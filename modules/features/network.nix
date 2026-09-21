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
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "The SOPS secret name for the Wi-Fi password. Required for wpa-psk and sae; omit for open networks (keyMgmt = none).";
              };
              security.keyMgmt = lib.mkOption {
                type = lib.types.enum [ "wpa-psk" "sae" "none" ];
                default = "wpa-psk";
                description = "Wi-Fi key management: wpa-psk (WPA2-Personal), sae (WPA3-Personal, PMF automatically required), or none (open network).";
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

      config = lib.mkIf (config.networking.enabledWifiNetworks != []) (
        let
          enabledNetworks = lib.filterAttrs (name: _: lib.elem name config.networking.enabledWifiNetworks) config.networking.wifiNetworks;
          networksWithSecrets = lib.filterAttrs (_: n: n.secretName != null) enabledNetworks;
        in
        {
          # Only enable iwd and NetworkManager Wi-Fi backend if at least one network is enabled
          networking.wireless.iwd.enable = true;
          networking.networkmanager.wifi.backend = "iwd";

          # Validate that non-open networks have secretName set
          assertions = lib.mapAttrsToList (name: network: {
            assertion = network.security.keyMgmt == "none" || network.secretName != null;
            message = "Wi-Fi network '${name}' has security.keyMgmt = '${network.security.keyMgmt}' but no secretName set.";
          }) enabledNetworks;

          # Generate sops secrets and NetworkManager profiles for networks with secrets
          sops.secrets = lib.mapAttrs' (
            name: network:
            lib.nameValuePair
              network.secretName
              { }
          ) networksWithSecrets;

          sops.templates = lib.mapAttrs' (
            name: network:
            lib.nameValuePair
              "wifi-${name}.env"
              {
                content = ''${lib.toUpper network.secretName}=${config.sops.placeholder.${network.secretName}}'';
              }
          ) networksWithSecrets;

          networking.networkmanager.ensureProfiles = {
            environmentFiles = lib.mapAttrsToList (
              name: _: config.sops.templates."wifi-${name}.env".path
            ) networksWithSecrets;
            profiles = lib.mapAttrs' (
              name: network:
              lib.nameValuePair
                name
                (
                  {
                    connection = {
                      id = name;
                      type = "wifi";
                    };
                    wifi = {
                      mode = "infrastructure";
                      ssid = network.ssid;
                    };
                    ipv4.method = "auto";
                    ipv6.method = "auto";
                  } // lib.optionalAttrs (network.security.keyMgmt != "none") {
                    wifi-security = {
                      key-mgmt = network.security.keyMgmt;
                      psk = "\${${lib.toUpper network.secretName}}";
                    } // lib.optionalAttrs (network.security.keyMgmt == "sae") {
                      pmf = "required";
                    };
                  }
                )
            ) enabledNetworks;
          };
        }
      );
    };
}

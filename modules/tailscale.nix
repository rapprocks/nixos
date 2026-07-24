{
  config,
  lib,
  ...
}:

let
  cfg = config.profiles.tailscale;
  hasRoutes = cfg.advertiseRoutes != [ ];
in
{
  options.profiles.tailscale = {
    enable = lib.mkEnableOption "Tailscale client for Headscale integration";

    authKeySecret = lib.mkOption {
      type = lib.types.str;
      description = "Name of the SOPS secret containing the Headscale pre-auth key";
    };

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://hs.rapprocks.se";
      description = "Headscale coordination server URL";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Subnet routes to advertise to the Tailnet (e.g. [ \"10.100.0.0/24\" ])";
    };

    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to advertise this node as an exit node";
    };
    acceptDns = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to accept MagicDNS";
    };
  };

  config = lib.mkIf cfg.enable {
    # Reference the secret from SOPS
    sops.secrets.${cfg.authKeySecret} = { };

    # Enable IP forwarding when advertising subnet routes
    boot.kernel.sysctl = lib.mkIf hasRoutes {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.${cfg.authKeySecret}.path;
      extraUpFlags = [
        "--login-server=${cfg.loginServer}"
        "--accept-dns=${lib.boolToString cfg.acceptDns}"
      ]
      ++ lib.optionals (cfg.advertiseRoutes != [ ]) [
        "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
      ]
      ++ lib.optionals cfg.exitNode [
        "--advertise-exit-node"
      ];
    };
  };
}

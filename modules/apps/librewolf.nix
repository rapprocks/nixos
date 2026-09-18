{ ... }:
{
  flake.nixosModules.librewolf =
    { pkgs, ... }:
    {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
          DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
          SearchBar = "unified"; # alternative: "separate"
          Preferences = {
            "cookiebanners.service.mode.privateBrowsing" = 2; # Block cookie banners in private browsing
            "cookiebanners.service.mode" = 2; # Block cookie banners
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.resistFingerprinting" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;

            ## ADDED BY ME
            "browser.startup.homepage" = "http://home-pve-1.rapp.rocks:3000";
            "browser.translations.neverTranslateLanguages" = "sv";
            "browser.newtabpage.enabled" = false;
            "browser.tabs.inTitlebar" = 0;
            "browser.download.autohideButton" = true;
            "sidebar.verticalTabs" = true;
            "sidebar.position_start" = false;
            "sidebar.visibility" = "always-show";
            "sidebar.main.tools" = "{446900e4-71c2-419f-a6a7-df9c091e268b}";

          };
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode = "force_installed";
            };
            # Bitwarden
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/{446900e4-71c2-419f-a6a7-df9c091e268b}/latest.xpi";
              installation_mode = "force_installed";
            };
            # Dark reader
            "addon@darkreader.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/addon@darkreader.org/latest.xpi";
              installation_mode = "force_installed";
            };
          };
          SearchEngines = {
            Add = [
              {
                "Name" = "NixOS Options";
                "URLTemplate" =
                  "https://search.nixos.org/options?channel=unstable&include_modular_service_options=1&include_nixos_options=1&query={searchTerms}";
                #"IconURL" =
                # "https://cdn.search.brave.com/serp/v1/static/brand/eebf5f2ce06b0b0ee6bbd72d7e18621d4618b9663471d42463c692d019068072-brave-lion-favicon.png";
                "Alias" = "nixo";
              }
            ];
          };
        };
      };
      environment.etc."firefox/policies/policies.json".target = "librewolf/policies/policies.json";
    };
}

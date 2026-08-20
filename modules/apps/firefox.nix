{ ... }:
{
  flake.nixosModules.firefox =
    { ... }:
    {
      programs.firefox = {
        enable = true;
        preferences = {
          #"browser.tabs.tabmanager.enabled" = false;
          "browser.translations.neverTranslateLanguages" = "sv";
          "browser.startup.homepage" = "http://home-pve-1.rapp.rocks:3000";
          "browser.newtabpage.enabled" = false;
          "sidebar.verticalTabs" = true;
          "sidebar.position_start" = false;
          "sidebar.visibility" = "always-show";
          "privacy.trackingprotection.enabled" = true;
          "widget.wayland.fractional-scale.enabled" = true;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };

        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          DisableAccounts = true;
          DisableFirefoxScreenshots = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          OfferToSaveLogins = false;
          DontCheckDefaultBrowser = true;
          DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
          DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
          SearchBar = "unified"; # alternative: "separate"

          SearchEngines = {
            Remove = [
              "eBay"
              "Bing"
              "Ecosia"
              "Wikipedia"
              "Perplexity"
            ];
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
            Default = "Google";
          };

          # ---- EXTENSIONS ----
          # Check about:support for extension/add-on ID strings.
          # Valid strings for installation_mode are "allowed", "blocked",
          # "force_installed" and "normal_installed".
          ExtensionSettings = {
            "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
            # Privacy Badger:
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode = "force_installed";
            };
            # Adguard adblocker
            "adguardadblocker@adguard.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguardadblocker@adguard.com/latest.xpi";
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
        };
      };
    };
}

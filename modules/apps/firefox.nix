{ ... }:
let
  basePreferences = {
    "browser.translations.neverTranslateLanguages" = "sv";
    "browser.startup.homepage" = "http://home-pve-1.rapp.rocks:3000";
    "browser.newtabpage.enabled" = false;
    "browser.tabs.inTitlebar" = 0;
    "browser.download.autohideButton" = true;
    "sidebar.verticalTabs" = true;
    "sidebar.position_start" = false;
    "sidebar.visibility" = "always-show";
    "sidebar.main.tools" = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
    "privacy.trackingprotection.enabled" = true;
  };

  policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
    DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
    SearchBar = "unified"; # alternative: "separate"
  };

  baseExtensions = {
    # Privacy Badger
    "jid1-MnnxcxisBPnSXQ@jetpack" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
      installation_mode = "force_installed";
    };
    # Dark reader
    "addon@darkreader.org" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/addon@darkreader.org/latest.xpi";
      installation_mode = "force_installed";
    };
  };

  bitwardenExtension = {
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/{446900e4-71c2-419f-a6a7-df9c091e268b}/latest.xpi";
      installation_mode = "force_installed";
    };
  };

  keeperExtension = {
    "KeeperFFStoreExtension@KeeperSecurityInc" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/file/4969396/keeper_password_manager-18.1.1.xpi";
      installation_mode = "force_installed";
    };
  };

  searchEngines = {
    Add = [
      {
        "Name" = "NixOS Options";
        "URLTemplate" =
          "https://search.nixos.org/options?channel=unstable&include_modular_service_options=1&include_nixos_options=1&query={searchTerms}";
        "Alias" = "nixo";
      }
    ];
  };
in
{
  flake.nixosModules.firefox =
    { config, ... }:
    let
      isWork = config.networking.hostName == "nixwork";

      # Select Keeper for work host, Bitwarden for personal/all others
      passwordManagerExtension = if isWork then keeperExtension else bitwardenExtension;

      # Only add Bitwarden sidebar preference if not on work host
      sidebarPreferences =
        if isWork then
          { "sidebar.main.tools" = "KeeperFFStoreExtension@KeeperSecurityInc"; }
        else
          {
            "sidebar.main.tools" = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
          };
    in
    {
      programs.firefox = {
        enable = true;
        preferences =
          basePreferences
          // sidebarPreferences
          // {
            "widget.wayland.fractional-scale.enabled" = true;
            "browser.urlbar.showSearchSuggestionsFirst" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1;
          };

        policies = policies // {
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

          SearchEngines = searchEngines // {
            Remove = [
              "eBay"
              "Bing"
              "Ecosia"
              "Wikipedia"
              "Perplexity"
            ];
            Default = "Google";
          };

          ExtensionSettings =
            baseExtensions
            // passwordManagerExtension
            // {
              "*".installation_mode = "blocked"; # blocks all addons except the ones specified here
              # Adguard adblocker
              "adguardadblocker@adguard.com" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguardadblocker@adguard.com/latest.xpi";
                installation_mode = "force_installed";
              };
            };
        };
      };

      environment.variables.BROWSER = "firefox";
      xdg.mime.enable = true;
      xdg.mime.defaultApplications = {
        "application/pdf" = "firefox.desktop";
        "default-web-browser" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "text/xml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
    };
}

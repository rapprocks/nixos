{ ... }:
let
  preferences = {
    "browser.translations.neverTranslateLanguages" = "sv";
    "browser.startup.homepage" = "http://home-pve-1.rapp.rocks:3000";
    "browser.newtabpage.enabled" = false;
    "browser.tabs.inTitlebar" = 0;
    "browser.download.autohideButton" = true;
    "browser.theme.toolbar-theme" = 0;
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

  extensions = {
    # Privacy Badger
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
  # Mutually exclusive alternatives: import exactly one, since both configure programs.firefox.
  flake.nixosModules.firefox =
    { ... }:
    {
      programs.firefox = {
        enable = true;
        preferences = preferences // {
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

          ExtensionSettings = extensions // {
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

  flake.nixosModules.librewolf =
    { pkgs, ... }:
    {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;
        policies = policies // {
          Preferences = preferences // {
            "cookiebanners.service.mode.privateBrowsing" = 2; # Block cookie banners in private browsing
            "cookiebanners.service.mode" = 2; # Block cookie banners
            "privacy.donottrackheader.enabled" = true;
            "privacy.fingerprintingProtection" = true;
            "privacy.resistFingerprinting" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
          };
          ExtensionSettings = extensions // {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
          };
          SearchEngines = searchEngines;
        };
      };
      environment.etc."firefox/policies/policies.json".target = "librewolf/policies/policies.json";

      environment.variables.BROWSER = "librewolf";
      xdg.mime.enable = true;
      xdg.mime.defaultApplications = {
        "application/pdf" = "librewolf.desktop";
        "default-web-browser" = [ "librewolf.desktop" ];
        "text/html" = [ "librewolf.desktop" ];
        "text/xml" = [ "librewolf.desktop" ];
        "x-scheme-handler/http" = [ "librewolf.desktop" ];
        "x-scheme-handler/https" = [ "librewolf.desktop" ];
      };
    };
}

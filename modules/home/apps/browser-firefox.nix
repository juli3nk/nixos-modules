{ pkgs, ... }:

{
  home.packages = with pkgs; [
    librewolf
  ];

  programs = {
    firefox = {
      enable = true;
      package = pkgs.firefox-wayland; # firefox with wayland support
      enableGnomeExtensions = false;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };
    };
  };
}

# Locale and i18n configuration
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.core.locale;
in
{
  options.myModules.nixos.core.locale = {
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_CA.UTF-8";
      example = "fr_CA.UTF-8";
      description = ''
        System default locale (LANG variable).
        This is the fallback for all LC_* variables.
      '';
    };

    regionalLocale = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "fr_CA.UTF-8";
      description = ''
        Regional locale for formats only (time, money, measurement, etc.).
        If null, uses defaultLocale everywhere (recommended).

        Note: This does NOT affect LC_MESSAGES (system messages stay in defaultLocale).
      '';
    };
  };

  config = {
    # System default locale (LANG)
    i18n.defaultLocale = cfg.defaultLocale;

    # Regional formats (LC_* variables)
    i18n.extraLocaleSettings = lib.mkIf (cfg.regionalLocale != null) {
      # Format settings
      LC_ADDRESS = cfg.regionalLocale;
      LC_IDENTIFICATION = cfg.regionalLocale;
      LC_MEASUREMENT = cfg.regionalLocale;
      LC_MONETARY = cfg.regionalLocale;
      LC_NAME = cfg.regionalLocale;
      LC_NUMERIC = cfg.regionalLocale;
      LC_PAPER = cfg.regionalLocale;
      LC_TELEPHONE = cfg.regionalLocale;
      LC_TIME = cfg.regionalLocale;

      # Collation (sorting)
      LC_COLLATE = cfg.regionalLocale;

      # Character classification
      LC_CTYPE = cfg.regionalLocale;

      # Messages stay in defaultLocale (intentional)
      # LC_MESSAGES = cfg.defaultLocale;
    };
  };
}

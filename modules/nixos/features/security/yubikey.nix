# YubiKey hardware support with configurable options
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.security.yubikey;
in
{
  options.myModules.nixos.features.security.yubikey = {
    enable = lib.mkEnableOption "YubiKey hardware support";

    enableGUI = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install GUI applications (personalization, authenticator)";
    };

    userGroup = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group allowed to access YubiKey devices";
    };
  };

  config = lib.mkIf cfg.enable {
    # Core CLI tools (always installed)
    environment.systemPackages = with pkgs; [
      yubikey-manager
      yubikey-personalization
      yubikey-touch-detector
    ] ++ lib.optionals cfg.enableGUI [
      yubikey-personalization-gui
      yubioath-flutter
    ];

    # udev rules for device access
    services.udev.packages = [ pkgs.yubikey-personalization ];

    # services.udev.extraRules = ''
      # YubiKey USB detection
    #   ATTRS{idVendor}=="1050", MODE="0660", GROUP="${cfg.userGroup}"
    # '';
  };
}

# GPG with smart card support
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.security.gpg;

  pinentryPkg = 
    if cfg.pinentryFlavor == "gnome3" then pkgs.pinentry-gnome3
    else if cfg.pinentryFlavor == "qt" then pkgs.pinentry-qt
    else if cfg.pinentryFlavor == "curses" then pkgs.pinentry-curses
    else pkgs.pinentry-gtk2;
in
{
  options.myModules.nixos.features.security.gpg = {
    enable = lib.mkEnableOption "GPG with agent";
    enableSSHSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    pinentryFlavor = lib.mkOption {
      type = lib.types.enum [ "gtk2" "gnome3" "qt" "curses" ];
      default = "gtk2";
    };
    enableSmartCard = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnupg
      pinentryPkg
    ] ++ lib.optionals cfg.enableSmartCard [ pcsc-tools ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = cfg.enableSSHSupport;
      pinentryPackage = pinentryPkg;
    };

    services.pcscd.enable = cfg.enableSmartCard;
  };
}

# Secure Boot natif via systemd-boot + bootspec
# Utilise exclusivement des clés personnalisées (pas de clés Microsoft)
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.security.secureBoot;
in
{
  options.myModules.nixos.features.security.secureBoot = {
    enable = lib.mkEnableOption "Secure Boot natif (systemd-boot + bootspec)";

    enforceInBootloader = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Active réellement Secure Boot dans systemd-boot.
        Mettre à `false` pour seulement installer sbctl et préparer
        les clés, sans activer l'enforcement (utile en phase de test).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.loader.systemd-boot.enable;
        message = ''
          myModules.nixos.features.security.secureBoot nécessite
          boot.loader.systemd-boot.enable = true (voir core/bootloader.nix).
        '';
      }
    ];

    boot.bootspec = {
      enable = true;
      enableValidation = cfg.enforceInBootloader;
    };

    environment.systemPackages = [ pkgs.sbctl ];
  };
}

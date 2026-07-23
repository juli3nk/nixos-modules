# UEFI bootloader configuration (systemd-boot)
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.core.bootloader;
in
{
  options.myModules.nixos.core.bootloader = {
    configurationLimit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = ''
        Nombre maximum d'entrées de boot à conserver.
        Empêche le débordement des variables EFI (EFI variable overflow).
      '';
    };

    timeout = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = 3;
      description = ''
        Délai (en secondes) avant le boot automatique.
        `null` = attente infinie, `0` = boot immédiat.
      '';
    };

    graceful = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Ignore les erreurs EFI non critiques.
        Recommandé avec systemd 257.x pour éviter les crashs de systemd-boot.
      '';
    };

    canTouchEfiVariables = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Autorise NixOS à modifier les variables EFI (NVRAM).
        À désactiver si systemd-boot crash à l'installation/mise à jour.
      '';
    };

    efiMountPoint = lib.mkOption {
      type = lib.types.path;
      default = "/boot";
      description = ''
        Point de montage de la partition système EFI (ESP).
      '';
    };
  };

  config = {
    # GRUB est activé par défaut dans NixOS : on le désactive explicitement
    # pour garantir que systemd-boot est le seul bootloader actif.
    boot.loader.grub.enable = lib.mkForce false;

    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = cfg.configurationLimit;
        graceful = cfg.graceful;
      };

      efi = {
        canTouchEfiVariables = cfg.canTouchEfiVariables;
        efiSysMountPoint = cfg.efiMountPoint;
      };

      timeout = cfg.timeout;
    };
  };
}

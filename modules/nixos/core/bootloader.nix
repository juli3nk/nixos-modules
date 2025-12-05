# UEFI bootloader configuration
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.core.bootloader;
in
{
  options.myModules.nixos.core.bootloader = {
    configurationLimit = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = ''
        Maximum number of boot entries to keep.
        Prevents EFI variable overflow.
      '';
    };

    timeout = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 3;
      description = ''
        Boot menu timeout in seconds.
        null = infinite, 0 = immediate boot
      '';
    };

    graceful = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Ignore non-critical EFI errors.
        Recommended with systemd 257.x to avoid crashes.
      '';
    };

    canTouchEfiVariables = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow NixOS to modify EFI variables.
        Set to false if experiencing systemd-boot crashes.
      '';
    };

    efiMountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/boot";
      description = ''
        EFI system partition mount point.
      '';
    };
  };

  config = {
    # Disable GRUB (enabled by default in NixOS)
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

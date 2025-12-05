# LUKS encryption configuration
# Provides full disk encryption with optional keyfile support
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.security.luks;
in
{
  options.myModules.nixos.features.security.luks = {
    enable = lib.mkEnableOption "LUKS full disk encryption";

    devices = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          device = lib.mkOption {
            type = lib.types.str;
            description = "Path to the encrypted device";
            example = "/dev/disk/by-uuid/xxxxx";
          };

          allowDiscards = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable TRIM support for SSD (security tradeoff)";
          };

          preLVM = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open device before LVM scan";
          };

          keyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to keyfile for auto-unlock";
            example = "/etc/luks/keyfile.bin";
          };

          fallbackToPassword = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Ask for password if keyfile fails";
          };
        };
      });
      default = {};
      description = "LUKS devices configuration";
    };

    enableCryptsetup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install cryptsetup tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # LUKS devices configuration
    boot.initrd.luks.devices = lib.mapAttrs (name: deviceCfg: {
      device = deviceCfg.device;

      # Keyfile configuration
      keyFile = deviceCfg.keyFile;
      keyFileSize = lib.mkIf (deviceCfg.keyFile != null) 4096;
      keyFileOffset = lib.mkIf (deviceCfg.keyFile != null) 0;

      # Fallback to password
      fallbackToPassword = deviceCfg.fallbackToPassword;

      # SSD optimization
      allowDiscards = deviceCfg.allowDiscards;

      # Boot options
      preLVM = deviceCfg.preLVM;

      # Performance
      bypassWorkqueues = true;  # Improve performance on modern CPUs
    }) cfg.devices;

    # Cryptsetup tools
    environment.systemPackages = lib.mkIf cfg.enableCryptsetup [
      pkgs.cryptsetup
    ];

    # Kernel modules for initrd
    boot.initrd.availableKernelModules = [
      "dm_crypt"
      "dm_mod"
      "aes"
      "xts"
      "sha256"
      "sha512"
    ];

    # Security: Clear terminal before asking password
    boot.initrd.preLVMCommands = lib.mkBefore ''
      clear
      echo "🔐 Unlocking encrypted root partition..."
    '';
  };
}

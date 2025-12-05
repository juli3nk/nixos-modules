# System maintenance (GC + store optimisation + tmp cleanup)
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.core.maintenance;
in
{
  options.myModules.nixos.core.maintenance = {
    gc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic garbage collection";
      };

      frequency = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "GC frequency (systemd calendar format)";
        example = "daily";
      };

      olderThan = lib.mkOption {
        type = lib.types.str;
        default = "30d";
        description = "Delete generations older than this";
        example = "7d";
      };
    };

    storeOptimisation = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Automatically deduplicate Nix store";
      };

      automatic = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Optimise after every build";
      };
    };

    cleanTmpOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Clean /tmp on system boot";
    };
  };

  config = {
    # Garbage collection
    nix.gc = lib.mkIf cfg.gc.enable {
      automatic = true;
      dates = cfg.gc.frequency;
      options = "--delete-older-than ${cfg.gc.olderThan}";
      persistent = true;
      randomizedDelaySec = "45min";
    };

    # Store optimisation
    nix.optimise = lib.mkIf cfg.storeOptimisation.enable {
      automatic = true;
      dates = [ cfg.gc.frequency ];  # Sync with GC
    };

    nix.settings = lib.mkIf cfg.storeOptimisation.automatic {
      auto-optimise-store = true;
    };

    # Clean /tmp on boot
    boot.tmp.cleanOnBoot = cfg.cleanTmpOnBoot;
  };
}

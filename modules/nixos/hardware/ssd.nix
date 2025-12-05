# SSD-specific optimizations
# Apply this module only for machines with SSD/NVMe storage
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.hardware.ssd;
in
{
  options.myModules.nixos.hardware.ssd = {
    enable = lib.mkEnableOption "SSD optimizations";

    enableContinuousTrim = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable continuous TRIM (discard mount option).
        WARNING: Can impact performance, prefer fstrim.timer instead.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Filesystem mount options
    fileSystems."/" = {
      options = lib.mkMerge [
        # Always apply for SSD
        [ "noatime" "nodiratime" ]

        # Optional continuous trim
        (lib.mkIf cfg.enableContinuousTrim [ "discard" ])
      ];
    };

    # Periodic TRIM (recommended over continuous)
    services.fstrim = lib.mkIf (!cfg.enableContinuousTrim) {
      enable = lib.mkDefault true;
      interval = "weekly";  # Can be overridden per-host
    };

    # SSD-friendly kernel parameters
    boot.kernelParams = [
      "elevator=none"      # Use none scheduler for NVMe/modern SSD
    ];

    # Reduce writes
    boot.kernel.sysctl = {
      "vm.swappiness" = lib.mkDefault 10;
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      "vm.dirty_ratio" = lib.mkDefault 10;
      "vm.dirty_background_ratio" = lib.mkDefault 5;
    };

    # Disable unnecessary services that write frequently
    services.journald.extraConfig = ''
      Storage=volatile
      RuntimeMaxUse=100M
    '';
  };
}

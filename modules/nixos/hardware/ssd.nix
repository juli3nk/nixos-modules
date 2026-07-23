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
        [ "noatime" ]

        # Optional continuous trim
        (lib.mkIf cfg.enableContinuousTrim [ "discard" ])
      ];
    };

    # Periodic TRIM (recommended over continuous)
    services.fstrim = lib.mkIf (!cfg.enableContinuousTrim) {
      enable = lib.mkDefault true;
      interval = "weekly";  # Can be overridden per-host
    };
  };
}

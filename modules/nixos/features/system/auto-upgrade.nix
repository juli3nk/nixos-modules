# Automatic NixOS system upgrades
#
# Safely updates system packages on a schedule.
# Requires manual reboot by default for safety.
#
# Usage:
#   features.autoUpgrade.enable = true;
#   features.autoUpgrade.dates = "weekly";

{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.system.autoUpgrade;
in
{
  options.myModules.nixos.features.system.autoUpgrade = {
    enable = lib.mkEnableOption "automatic system upgrades";

    allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Allow automatic reboot after upgrade.
        WARNING: Only enable on non-critical systems.
      '';
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:00";
      description = ''
        When to run upgrades (systemd.time format).
        Examples: "04:00", "daily", "weekly", "Mon,Fri 02:00"
      '';
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "45min";
      description = "Random delay before upgrade (prevents thundering herd)";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run missed upgrades on next boot";
    };

    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Flake URI to upgrade from";
      example = "github:user/nixos-config";
    };

    operation = lib.mkOption {
      type = lib.types.enum [ "switch" "boot" ];
      default = "switch";
      description = ''
        How to activate the new configuration:
        - switch: Immediate activation (may restart services)
        - boot: Activate on next reboot (safer)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      allowReboot = cfg.allowReboot;
      dates = cfg.dates;
      randomizedDelaySec = cfg.randomizedDelaySec;
      persistent = cfg.persistent;

      # Flake-based upgrade
      flake = lib.mkIf (cfg.flake != null) cfg.flake;

      # Upgrade flags
      flags = [
        "--upgrade-all"
        "--delete-older-than" "30d"
        "--option" "tarball-ttl" "0"  # Force channel update
      ] ++ lib.optional (cfg.operation == "boot") "--no-build-nix";

      # Operation mode
      operation = cfg.operation;
    };

    # Enhanced systemd service
    systemd.services.nixos-upgrade = {
      # Run with limited resources (avoid system strain)
      serviceConfig = {
        CPUQuota = "50%";
        IOSchedulingClass = "idle";
        Nice = 19;
      };

      # Environment for better logging
      environment = {
        NIXOS_UPGRADE_LOG = "/var/log/nixos-upgrade.log";
      };
    };

    # Cleanup old boot entries (keep last 5)
    boot.loader.grub.configurationLimit = lib.mkDefault 5;
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;

    # Log rotation for upgrade logs
    services.logrotate.settings.nixos-upgrade = {
      files = [ "/var/log/nixos-upgrade.log" ];
      frequency = "monthly";
      rotate = 3;
      compress = true;
    };
  };
}

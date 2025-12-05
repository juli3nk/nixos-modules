{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.hardware;
in
{
  options.myModules.nixos.features.packages.hardware = {
    enable = lib.mkEnableOption "hardware information and management tools";

    includeStorage = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include storage management tools (nvme-cli, smartmontools)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Basic hardware info
      pciutils         # PCI bus and device utilities (lspci)
      usbutils         # USB device utilities (lsusb)
      dmidecode        # DMI/SMBIOS table decoder for hardware information
      lshw             # Hardware information listing tool

      # Disk utilities
      hdparm           # Hard disk drive parameters and performance tuning

      # Network hardware
      ethtool          # Ethernet device configuration and statistics

      # Sensors
      lm_sensors       # Hardware monitoring tools for temperature, voltage, fans
    ] ++ lib.optionals cfg.includeStorage [
      nvme-cli         # NVMe storage management and monitoring tools
      smartmontools    # SMART disk health monitoring and self-test utilities
    ];
  };
}

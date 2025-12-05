{ ... }:

{
  # Framework Laptop specific
  boot.kernelParams = [
    "nvme.noacpi=1"
  ];

  # Fingerprint reader
  services.fprintd.enable = true;

  # Support expansion cards
  hardware.enableAllFirmware = true;

  # Firmware updates
  # The Framework Laptop has open-source firmware that updates via fwupd
  services.fwupd.enable = true;
}

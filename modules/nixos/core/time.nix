# Base time configuration
# NOTE: time.timeZone is defined in hosts/<hostname>/default.nix
{ ... }:

{
  # Hardware clock in UTC (standard)
  time.hardwareClockInLocalTime = false;
}

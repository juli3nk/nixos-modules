# Disable IPv6 system-wide
# Use for legacy systems or IPv4-only networks
{ ... }:

{
  boot.kernelParams = [ "ipv6.disable=1" ];
  networking.enableIPv6 = false;
}

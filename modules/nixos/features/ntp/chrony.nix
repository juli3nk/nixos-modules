# NTP client using chrony (for laptops/mobile devices)
{ ... }:

{
  services.chrony = {
    enable = true;

    # NTP servers
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    # Extra configuration for mobility
    extraConfig = ''
      # Allow time to jump on boot (useful for suspended laptops)
      makestep 1.0 3

      # No NTP server (client only)
      port 0
    '';
  };

  # Disable systemd-timesyncd (conflicts with chrony)
  services.timesyncd.enable = false;
}

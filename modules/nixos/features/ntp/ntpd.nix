# NTP client using ntpd (for servers)
{ ... }:

{
  services.ntp = {
    enable = true;

    # NTP servers (pool.ntp.org)
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    # Restrictive config (no LAN server)
    extraConfig = ''
      # Block all external access
      restrict default ignore
      restrict -6 default ignore

      # Localhost seulement
      restrict 127.0.0.1
      restrict ::1
    '';
  };

  # Disable systemd-timesyncd (conflicts with ntpd)
  services.timesyncd.enable = false;
}

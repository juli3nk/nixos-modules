{ config, lib, pkgs, ... }:

{
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "systemd.show_status=auto"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
    ];

    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  # Hide systemd messages
  systemd.services = {
    "systemd-udev-settle".enable = false;
    "NetworkManager-wait-online".enable = false;
  };
}

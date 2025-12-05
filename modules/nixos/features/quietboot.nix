{ config, lib, pkgs, ... }:

{
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "vt.global_cursor_default=0"
      "systemd.show_status=auto"
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

  systemd.network.wait-online.enable = false;

  # environment.systemPackages = with pkgs; [
  #   catppuccin-plymouth
  # ];
}

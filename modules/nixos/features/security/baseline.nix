{ ... }:

{
  # Keep sudo password (secure default)
  security.sudo.wheelNeedsPassword = true;

  # Non-intrusive hardening
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;  # Safe everywhere
  };

  # Base services
  security.polkit.enable = true;
}

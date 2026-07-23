{ ... }:

{
  # Keep sudo password (secure default)
  security.sudo.wheelNeedsPassword = true;

  # Non-intrusive hardening
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;

    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
  };
}

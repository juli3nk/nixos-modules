# UEFI bootloader configuration
{ ... }:

{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    
    # Boot menu timeout
    timeout = 3;
  };
}

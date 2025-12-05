# Workstation profile
{ ... }:

{
  imports = [
    ./base.nix

    ../hardware/bluetooth.nix
    ../hardware/sound.nix

    ../features/ntp/chrony.nix
  ];

  # Desktop environment placeholder
  # services.xserver.enable = true;
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
}

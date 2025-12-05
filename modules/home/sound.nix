{ pkgs, ... }:

{
  home.packages = with pkgs; [
    alsa-utils # provides amixer/alsamixer/...

    # audio control
    pulsemixer
    pwvucontrol
    # pavucontrol
    # pasystray
  ];
}

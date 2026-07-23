{ pkgs, ... }:

{
  home.packages = with pkgs; [
    swaybg # the wallpaper
    swayr

    cliphist
    # copyq

    trash-cli   # Command line interface to the freedesktop.org trashcan
  ];
}

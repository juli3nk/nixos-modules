{ pkgs, ... }:

{
  home.packages = with pkgs; [
    swaybg # the wallpaper
    swayidle # the idle timeout
    swaylock # locking the screen
    swayr

    cliphist
    copyq

    trash-cli   # Command line interface to the freedesktop.org trashcan
  ];
}

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gimp
    inkscape
    scribus

    imv          # simple image viewer
    viu          # Terminal image viewer with native support for iTerm and Kitty
    imagemagick
    graphviz
  ];
}

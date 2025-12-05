{ pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    libnotify
    avizo
  ] ++ (with pkgs-unstable; [
    swaynotificationcenter
  ]);
}

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar # xfce4's file manager
    ffmpegthumbnailer
    mate.atril
    mate.caja
    mate.engrampa
    mate.mate-calc
    mate.eom
  ];
}

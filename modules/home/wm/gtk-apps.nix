{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpegthumbnailer
    atril
    caja
    engrampa
    mate-calc
    eom
  ];
}

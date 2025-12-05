{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg-full
    vlc
  ];
}

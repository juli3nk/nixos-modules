{ pkgs, ... }:

{
  home.packages = with pkgs; [
    qt5.full
  ];
}

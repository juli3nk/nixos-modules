{ pkgs, ... }:

{
  home.packages = with pkgs; [
    opencode
    opencode-desktop
  ];
}

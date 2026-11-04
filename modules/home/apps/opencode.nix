{ pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    opencode
  ];
  # ++ (with pkgs-unstable; [
  #  opencode-desktop
  # ]);
}

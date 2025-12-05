{ pkgs, ... }:

{
  home.packages = with pkgs; [
    protonvpn-gui
    protonvpn-cli_2
  ];
}

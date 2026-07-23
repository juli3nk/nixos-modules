{ pkgs, ... }:

{
  home.packages = with pkgs; [
    proton-authenticator
    proton-pass
    proton-pass-cli
    proton-vpn
    proton-vpn-cli
  ];
}

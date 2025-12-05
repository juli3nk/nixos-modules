{ pkgs, ... }:

{
  home.packages = with pkgs; [
    playerctl

    mpd     # for playing system sounds
    mpc-cli # command-line mpd client
  ];

  services = {
    playerctld.enable = true;
  };
}
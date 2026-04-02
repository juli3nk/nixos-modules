{ pkgs, ... }:

{
  home.packages = with pkgs; [
    playerctl

    mpd # for playing system sounds
    mpc # command-line mpd client
  ];

  services = {
    playerctld.enable = true;
  };
}

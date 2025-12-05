{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wayland
    xwayland

    wlogout      # logout menu
    wl-clipboard # copying and pasting

    dmenu-wayland
    eww
    fuzzel

    waybar       # the status bar

    wf-recorder  # screen recording
    grim         # taking screenshots
    slurp        # selecting a region to screenshot
    # TODO replace by `flameshot gui --raw | wl-copy`

    wlsunset

    udiskie
  ];
}

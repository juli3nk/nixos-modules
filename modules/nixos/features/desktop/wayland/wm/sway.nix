{ config, lib, pkgs, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;  # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      wofi         # launcher
      waybar
      grim         # screenshots
      slurp
      wf-recorder  # screen recording
      dex
      glib
    ];
    extraSessionCommands = ''
      # Force GTK to use wayland
      export GDK_BACKEND="wayland"
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM="wayland"
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export CLUTTER_BACKEND="wayland"
      export SDL_VIDEODRIVER="wayland"
      export MOZ_ENABLE_WAYLAND="1"
      export XDG_SESSION_TYPE="wayland"
    '';
  };

  # Allow swaylock to unlock
  security.pam.services.swaylock = {};

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}

{ pkgs, ... }:

{
  # XDG Base Directory
  environment.variables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.common.default = "*";
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
    xdg-utils     # provides cli tools such as `xdg-mime` `xdg-open`
  ];
}

# Thunar file manager with full desktop integration
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.desktop.thunar;
in
{
  options.myModules.nixos.features.desktop.thunar = {
    enable = lib.mkEnableOption "Thunar file manager";

    enablePlugins = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Thunar plugins";
    };

    enableThumbnails = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable thumbnail generation";
    };

    enableAutoMount = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic device mounting";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = lib.mkIf cfg.enablePlugins (with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ]);
    };

    services.gvfs.enable = cfg.enableAutoMount;
    services.udisks2.enable = cfg.enableAutoMount;
    services.tumbler.enable = cfg.enableThumbnails;

    # Archive manager for thunar-archive-plugin
    environment.systemPackages = lib.mkIf cfg.enablePlugins [
      pkgs.xarchiver
    ];
  };
}

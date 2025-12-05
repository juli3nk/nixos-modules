{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.systemInfo;
in
{
  options.myModules.nixos.features.packages.systemInfo.enable = lib.mkEnableOption "system information tools";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lsb-release    # Linux Standard Base release information
    ];
  };
}

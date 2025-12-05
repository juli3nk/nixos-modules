{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.nixTools;
in
{
  options.myModules.nixos.features.packages.nixTools.enable = lib.mkEnableOption "Nix-specific tools";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nix-output-monitor  # Enhanced nix build output
      nvd
    ];
  };
}

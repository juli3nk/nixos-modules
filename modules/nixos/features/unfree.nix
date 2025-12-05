{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.unfree;
in
{
  options.myModules.nixos.features.unfree = {
    enable = lib.mkEnableOption "unfree packages";
    
    allow = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Allowed unfree package names";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) cfg.allow;
  };
}

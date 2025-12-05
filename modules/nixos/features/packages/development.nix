{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.development;
in
{
  options.myModules.nixos.features.packages.development = {
    enable = lib.mkEnableOption "development tools";

    includeGitExtras = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include git extras and LFS support";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git              # Distributed version control system
      pwgen            # Automatic password generation tool
    ] ++ lib.optionals cfg.includeGitExtras [
      gitAndTools.git-extras  # Additional git utilities
      git-lfs                 # Git Large File Storage
    ];
  };
}

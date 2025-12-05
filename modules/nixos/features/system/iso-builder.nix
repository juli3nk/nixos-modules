{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.system.iso-builder;
  
  profiles = {
    minimal = {
      compression = "zstd -Xcompression-level 10";
      size = "small";
    };
    balanced = {
      compression = "zstd -Xcompression-level 15";
      size = "medium";
    };
    maximum = {
      compression = "xz -Xdict-size 100%";
      size = "large";
    };
  };
in
{
  options.myModules.nixos.features.system.iso-builder = {
    enable = lib.mkEnableOption "ISO Toolkit configuration";

    profile = lib.mkOption {
      type = lib.types.enum [ "minimal" "balanced" "maximum" ];
      default = "balanced";
      description = "Profil de compression à utiliser";
    };

    customName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Nom personnalisé pour l'ISO";
    };

    volumeID = lib.mkOption {
      type = lib.types.str;
      default = "NIXOS_TOOLKIT";
      description = "Volume ID de l'ISO";
    };
  };

  config = lib.mkIf cfg.enable {
    isoImage = {
      isoName = lib.mkForce (
        if cfg.customName != null 
        then "${cfg.customName}-${pkgs.stdenv.hostPlatform.system}.iso"
        else "nixos-toolkit-${pkgs.stdenv.hostPlatform.system}.iso"
      );
      squashfsCompression = profiles.${cfg.profile}.compression;
      makeEfiBootable = true;
      makeUsbBootable = true;
      volumeID = cfg.volumeID;
    };
  };
}

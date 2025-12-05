{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.compression;
in
{
  options.myModules.nixos.features.packages.compression = {
    enable = lib.mkEnableOption "compression and archive tools";

    formats = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "tar" "zip" "7z" "xz" "lzip" "zstd" ]);
      default = [ "tar" "zip" "xz" "lzip" "zstd" ];
      description = "Compression formats to support";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      zlib             # Compression library (used by many applications)
    ] ++ lib.optionals (builtins.elem "tar" cfg.formats) [
      gnutar           # GNU tar archiving utility
    ] ++ lib.optionals (builtins.elem "zip" cfg.formats) [
      zip              # ZIP archive creation tool
      unzip            # Extract ZIP archives
    ] ++ lib.optionals (builtins.elem "7z" cfg.formats) [
      p7zip            # 7-Zip file archiver
    ] ++ lib.optionals (builtins.elem "xz" cfg.formats) [
      xz               # XZ compression utilities
    ] ++ lib.optionals (builtins.elem "lzip" cfg.formats) [
      lzip             # LZMA-based compression tool
    ] ++ lib.optionals (builtins.elem "zstd" cfg.formats) [
      zstd             # Zstandard fast compression algorithm
    ];
  };
}

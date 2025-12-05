{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.crypto.libressl;
in
{
  options.myModules.nixos.features.crypto.libressl = {
    enable = lib.mkEnableOption "Use LibreSSL instead of OpenSSL";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "curl" "openssh" ];
      description = "Packages to build with LibreSSL";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev:
        lib.genAttrs cfg.packages (name:
          prev.${name}.override { openssl = prev.libressl_4_0; }
        )
      )
    ];
  };
}

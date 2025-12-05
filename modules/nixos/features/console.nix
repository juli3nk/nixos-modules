{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.console;
in
{
  options.myModules.nixos.features.console = {
    enable = lib.mkEnableOption "console customization";

    keyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      example = "cf";
      description = ''
        Console (TTY) keyboard layout.
        Common layouts:
        - us: US QWERTY
        - cf: Canadian French
        - ca: Canadian Multilingual
        - fr: French AZERTY
      '';
    };

    font = lib.mkOption {
      type = lib.types.str;
      default = "Lat2-Terminus16";
      example = "ter-v32n";
      description = ''
        Console font.
        Recommended for HiDPI: ter-v32n
      '';
    };

    earlySetup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Configure console early in boot.
        Enable if you need:
        - Non-US keyboard for LUKS password
        - Custom font during boot
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    console = {
      keyMap = cfg.keyMap;
      font = cfg.font;
      earlySetup = cfg.earlySetup;
    };
  };
}

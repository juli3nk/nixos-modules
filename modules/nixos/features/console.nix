{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.console;

  # Détection automatique LUKS
  hasLuks = builtins.length (builtins.attrNames config.boot.initrd.luks.devices) > 0;

  # Vérifier si keymap non-US nécessite earlySetup
  needsEarlySetup = hasLuks && (cfg.keyMap != "us");
in
{
  options.myModules.nixos.features.console = {
    enable = lib.mkEnableOption "console customization";

    profile = lib.mkOption {
      type = lib.types.enum [ "standard" "hidpi" "custom" ];
      default = "standard";
      description = ''
        Preset configurations for common use cases:
        - standard: US layout, standard resolution (1080p)
        - hidpi: US layout, high resolution (4K/Retina)
        - custom: Use manual settings below
      '';
    };

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

        Note: Used only with 'custom' profile.
      '';
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;  # Fix: package, pas packages
      default = [];
      example = lib.literalExpression "[ pkgs.powerline-fonts ]";
      description = ''
        List of additional packages that provide console fonts,
        keymaps and other resources for virtual consoles use.
      '';
    };

    font = lib.mkOption {
      type = lib.types.str;
      default = "ter-v16n";
      example = "ter-v32n";
      description = ''
        Console font.
        Common sizes:
        - ter-v16n: Standard (1080p and below)
        - ter-v22n: Medium (1440p)
        - ter-v32n: Large (4K/HiDPI)

        Note: Used only with 'custom' profile.
      '';
    };

    earlySetup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Configure console early in boot.

        Automatically recommended when:
        - LUKS encryption is detected with non-US keyboard
        - HiDPI display needs readable boot messages

        Note: Used only with 'custom' profile.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Package Terminus toujours inclus + packages additionnels
    {
      console.packages = [ pkgs.terminus_font ] ++ cfg.packages;
    }

    # Profil: standard (1080p)
    (lib.mkIf (cfg.profile == "standard") {
      console = {
        keyMap = lib.mkDefault "us";
        font = lib.mkDefault "ter-v16n";
        earlySetup = lib.mkDefault false;
      };
    })

    # Profil: hidpi (4K)
    (lib.mkIf (cfg.profile == "hidpi") {
      console = {
        keyMap = lib.mkDefault "us";
        font = lib.mkDefault "ter-v32n";
        earlySetup = lib.mkDefault true;
      };
    })

    # Profil: custom (configuration manuelle)
    (lib.mkIf (cfg.profile == "custom") {
      console = {
        keyMap = cfg.keyMap;
        font = cfg.font;
        earlySetup = cfg.earlySetup;
      };
    })

    # Warnings intelligents
    {
      warnings = lib.optionals (cfg.profile == "custom") [
        (lib.optionalString
          (needsEarlySetup && !cfg.earlySetup)
          ''
            Console: LUKS encryption detected with non-US keyboard layout (${cfg.keyMap}).
            Consider enabling 'earlySetup = true' to avoid typing LUKS password
            with wrong keyboard layout during boot.
          ''
        )
      ];
    }

    # Assertions de sécurité
    {
      assertions = [
        {
          assertion = cfg.profile == "custom" -> cfg.font != "";
          message = "Console: font cannot be empty when using 'custom' profile";
        }
        {
          assertion = cfg.profile == "custom" -> cfg.keyMap != "";
          message = "Console: keyMap cannot be empty when using 'custom' profile";
        }
      ];
    }
  ]);
}

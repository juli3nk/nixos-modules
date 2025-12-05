# Secret management with conditional polkit agent
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.security.secrets;
in
{
  options.myModules.nixos.features.security.secrets = {
    enable = lib.mkEnableOption "secret management (keyring + polkit)";
    
    polkitAgent = lib.mkOption {
      type = lib.types.enum [ "mate" "gnome" "kde" ];
      default = "mate";
      description = "Which polkit authentication agent to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Polkit (GUI authentication)
    security.polkit.enable = true;

    # GNOME Keyring
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;

    # Polkit agent (desktop environment specific)
    environment.systemPackages = with pkgs; [
      libsecret
      seahorse
    ] ++ (if cfg.polkitAgent == "mate" then [ mate.mate-polkit ]
         else if cfg.polkitAgent == "gnome" then [ polkit_gnome ]
         else if cfg.polkitAgent == "kde" then [ libsForQt5.polkit-kde-agent ]
         else []);
  };
}

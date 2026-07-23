# Secret management with conditional polkit agent
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.desktop.secrets;
in
{
  options.myModules.nixos.features.desktop.secrets = {
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
    ] ++ {
      mate = [ mate-polkit ];
      gnome = [ polkit_gnome ];
      kde = [ libsForQt5.polkit-kde-agent ];
    }.${cfg.polkitAgent};
  };
}

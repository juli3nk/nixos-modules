# Concept : LUKS + SSH initrd
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.security.luks.remote-unlock;
in
{
  options.myModules.nixos.features.security.luks.remote-unlock = {
    enable = lib.mkEnableOption "LUKS full disk encryption";

    sshPort = lib.mkOption {
      type = lib.types.int;
      default = 2222;
      description = "Different port from normal SSH";
    };

    hostKeys = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      description = "Specify SSH host keys to import into the initrd";
      example = lib.literalExpression ''
        [
          "/etc/secrets/initrd/ssh_host_rsa_key"
          "/etc/secrets/initrd/ssh_host_ed25519_key"
        ]
      '';
    };

    authorizedKeyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of PEM certificate files to add to system trust store.
        Files should contain X.509 certificates in PEM format.
      '';
      example = lib.literalExpression ''
        [
          ./secrets/certificates/homelab-ca.crt
          ./secrets/certificates/company-ca.crt
        ]
      '';
    };

    authorizedKeyStrings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of PEM certificates as strings.
        Useful for certificates from secrets management.
      '';
      example = lib.literalExpression ''
        [
          "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
          "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd = {
      # Enable network in initrd
      network.enable = true;

      # SSH in initrd
      network.ssh = {
        enable = true;
        port = cfg.sshPort;

        hostKeys = cfg.hostKeys;

        # SSH key authorized for unlock
        authorizedKeys =
        # From files
        (map (file: builtins.readFile file) cfg.authorizedKeyFiles)
        ++
        # From strings
        cfg.authorizedKeyStrings;

        # Command available after connection
        # Ex: "cryptsetup luksOpen /dev/sda2 cryptroot"
      };
    };
  };
}

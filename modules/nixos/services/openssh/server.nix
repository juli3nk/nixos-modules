{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.services.openssh.server;
in
{
  options.myModules.nixos.services.openssh.server = {
    enable = lib.mkEnableOption "OpenSSH server with secure defaults";

    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "SSH server port";
    };

    allowedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "alice" "bob" ];
      description = "Users allowed to connect via SSH (empty = all users)";
    };

    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication (insecure)";
    };

    rootLogin = lib.mkOption {
      type = lib.types.enum [ "yes" "prohibit-password" "forced-commands-only" "no" ];
      default = "prohibit-password";
      description = "Root login policy";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {};
      example = {
        alice = [ "ssh-ed25519 AAAA..." ];
        bob = [ "ssh-rsa AAAA..." ];
      };
      description = "Authorized SSH keys per user";
    };

    hardening = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply security hardening";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra SSH server configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # OpenSSH server
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];

      settings = {
        # Authentication
        PasswordAuthentication = cfg.passwordAuthentication;
        PermitRootLogin = cfg.rootLogin;
        PubkeyAuthentication = true;
        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;
        UsePAM = true;

        # User restrictions
        AllowUsers = lib.mkIf (cfg.allowedUsers != []) cfg.allowedUsers;

        # Security
        PermitEmptyPasswords = false;
        X11Forwarding = false;
        PrintMotd = false;
        
        # Performance
        UseDns = false;

        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";

        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
      } // lib.optionalAttrs cfg.hardening {
        # Hardening options
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "hmac-sha2-512"
          "hmac-sha2-256"
        ];
        
        # Additional hardening
        MaxAuthTries = 3;
        MaxSessions = 10;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        LoginGraceTime = 60;
      };

      # Extra configuration
      extraConfig = cfg.extraConfig;

      # Host keys (ED25519 + RSA for compatibility)
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];

      startWhenNeeded = true;
      # openFirewall = true;
    };

    # Authorized keys per user
    users.users = lib.mapAttrs (name: keys: {
      openssh.authorizedKeys.keys = keys;
    }) cfg.authorizedKeys;

    # Firewall
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}

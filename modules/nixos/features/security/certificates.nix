# Custom PKI certificates management
# Add custom Certificate Authorities to system trust store
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.security.certificates;
in
{
  options.myModules.nixos.features.security.certificates = {
    enable = lib.mkEnableOption "custom certificates";

    certificateFiles = lib.mkOption {
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

    certificateStrings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of PEM certificates as strings.
        Useful for certificates from secrets management.
      '';
      example = lib.literalExpression ''
        [
          '''
            -----BEGIN CERTIFICATE-----
            MIIDXTCCAkWgAwIBAgIJAKJ...
            -----END CERTIFICATE-----
          '''
        ]
      '';
    };

    verifyOnBuild = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Verify certificates are valid PEM on rebuild";
    };
  };

  config = lib.mkIf cfg.enable {
    # Read certificate files
    security.pki.certificates =
      # From files
      (map (file: builtins.readFile file) cfg.certificateFiles)
      ++
      # From strings
      cfg.certificateStrings;

    # Verification script (optional)
    system.activationScripts.verifyCertificates = lib.mkIf cfg.verifyOnBuild ''
      echo "[INFO] Verifying custom PKI certificates..."

      ${lib.concatMapStrings (file: ''
        if ! ${pkgs.openssl}/bin/openssl x509 -in ${file} -noout 2>/dev/null; then
          echo "[ERROR] Invalid certificate: ${file}"
          exit 1
        fi
        if ! ${pkgs.openssl}/bin/openssl x509 -in ${file} -checkend 0 -noout 2>/dev/null; then
          echo "[ERROR] Expired certificate: ${file}"
          exit 1
        fi
      '') cfg.certificateFiles}

      echo "[OK] All certificates valid"
    '';

    # Install OpenSSL tools
    environment.systemPackages = [ pkgs.openssl ];
  };
}

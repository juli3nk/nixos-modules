# Server profile
{ ... }:

{
  imports = [
    ./base.nix

    ../features/ntp/ntpd.nix
    ../features/security/baseline.nix
    ../features/security/hardened.nix
    ../features/system/filesystem.nix
    ../features/console.nix
    ../features/fonts.nix
    ../features/networking.nix

    ../services/prometheus/node-exporter.nix
    ../services/openssh/server.nix
  ];

  myModules.nixos.services.prometheus.nodeExporter.enable = true;

  myModules.nixos.services.openssh.server = {
    enable = true;
    passwordAuthentication = true;
    rootLogin = "no";
  };
}

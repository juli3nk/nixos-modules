# Base profile (imported by all other profiles)
{ pkgs, ... }:

{
  imports = [
    ../core/bootloader.nix
    ../core/locale.nix
    ../core/maintenance.nix
    ../core/nix.nix
    ../core/nixpkgs.nix
    ../core/time.nix

    ../features/packages
  ];

  # To keep logs after reboot and detect anomalies
  services.journald.extraConfig = "Storage=persistent";

  # Prevents sensitive temporary files from being written to disk
  boot.tmp.useTmpfs = true;

  myModules.nixos.features.packages = {
    systemInfo.enable = true;

    hardware.enable = true;
    hardware.includeStorage = true;

    shell.enable = true;

    utilities.enable = true;
    utilities.modernAlternatives = true;
    utilities.includeContainers = true;

    monitoring.enable = true;
    monitoring.level = "full";

    networking.enable = true;
    networking.includeDownloaders = true;
    networking.includeDiagnostics = true;
    networking.includeMonitoring = true;

    textProcessing.enable = true;
    textProcessing.modernTools = true;

    compression.enable = true;
    editors.vim.enable = true;
    editors.neovim.enable = true;

    development.enable = true;
    development.includeGitExtras = true;

    nixTools.enable = true;
  };
}

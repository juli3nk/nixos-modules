{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.utilities;
in
{
  options.myModules.nixos.features.packages.utilities = {
    enable = lib.mkEnableOption "general system utilities";

    modernAlternatives = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install modern alternatives (fd, bat, ripgrep, etc.)";
    };

    includeContainers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include container-related tools (proot)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Core utilities
      bc               # Arbitrary precision calculator language
      which            # Locate command executable in PATH
      less             # Terminal pager for viewing file contents
      man              # Manual page viewer and documentation system
      watch            # Execute a program periodically and display output
      parallel         # GNU parallel for parallel execution of jobs
      patch            # Apply patch files to source code
      time             # Command execution time measurement utility

      # Enhanced utilities
      moreutils        # Collection of additional Unix utilities
      rsync            # Fast and versatile file copying and synchronization tool

      # Help systems
      tldr             # Simplified and community-driven command documentation
      tealdeer         # Fast tldr client implementation written in Rust

      # File utilities
      tree             # Recursive directory tree visualization
      file             # File type identification using magic numbers
      pv               # Pipe viewer for monitoring data progress through pipes

      # Benchmarking
      hyperfine        # Command-line benchmarking tool
    ] ++ lib.optionals cfg.modernAlternatives [
      fd               # Fast and user-friendly alternative to find
      bat              # Cat clone with syntax highlighting
      duf              # Disk usage utility with better formatting
      ncdu             # Interactive disk usage analyzer
    ] ++ lib.optionals cfg.includeContainers [
      proot            # User-space chroot implementation
    ];
  };
}

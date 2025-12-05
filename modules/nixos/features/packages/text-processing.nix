{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.textProcessing;
in
{
  options.myModules.nixos.features.packages.textProcessing = {
    enable = lib.mkEnableOption "text processing and search tools";

    modernTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include modern alternatives (ripgrep, sd, bat)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Traditional GNU tools
      gnugrep          # GNU grep for pattern matching in text files
      gnused           # GNU sed for stream editing and text transformation
      gawk             # GNU awk for pattern scanning and data extraction

      # Pagers
      less             # Terminal pager for viewing file contents
      most             # Terminal pager with improved features

      # JSON processing
      jq               # Lightweight command-line JSON processor
    ] ++ lib.optionals cfg.modernTools [
      ripgrep          # Fast recursive regex search tool
      sad              # CLI search and replace tool with diff preview
      sd               # Intuitive find & replace CLI tool
    ];
  };
}

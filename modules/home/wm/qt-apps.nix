{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kdePackages.dolphin  # File Manager
    kdePackages.okular   # Document Viewer
    kdePackages.ark      # Archiving Tool
    kdePackages.gwenview # Image Viewer
    kdePackages.kcalc    # Scientific Calculator
    kdePackages.kcolorchooser # Color Chooser
  ];
}

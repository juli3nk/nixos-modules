{ pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebkit-5.212.0-alpha4"
  ];

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    libsForQt5.breeze-icons
    libsForQt5.kemoticons
    libsForQt5.oxygen-icons5
    libsForQt5.dolphin  # File Manager
    libsForQt5.okular   # Document Viewer
    libsForQt5.ark      # Archiving Tool
    libsForQt5.gwenview # Image Viewer
    libsForQt5.kcalc    # Scientific Calculator
    libsForQt5.kcolorchooser # Color Chooser
  ];
}

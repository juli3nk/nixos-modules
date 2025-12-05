{ pkgs, ... }:

{
  home.packages = with pkgs; [
    f3d
    freecad
    openscad
    orca-slicer
    # prusa-slicer
    kicad
  ];
}

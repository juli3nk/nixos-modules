{ pkgs, ... }:

{
  home.packages = [
    (pkgs.kodi.withPackages (p: with p; [
      inputstream-adaptive
      inputstream-ffmpegdirect
      pvr-iptvsimple
      osmc-skin
    ]))
  ];
}

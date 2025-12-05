{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.editors;
in
{
  options.myModules.nixos.features.packages.editors = {
    vim.enable = lib.mkEnableOption "Vim editor";
    neovim.enable = lib.mkEnableOption "Neovim editor";
  };

  config = {
    environment.systemPackages = with pkgs;
      (lib.optionals cfg.vim.enable [ vim ]) ++
      (lib.optionals cfg.neovim.enable [ neovim ]);
  };
}

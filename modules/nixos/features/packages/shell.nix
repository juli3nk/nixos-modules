{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.shell;
in
{
  options.myModules.nixos.features.packages.shell.enable = lib.mkEnableOption "shell utilities and enhancements";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bash             # Bourne Again SHell
      bash-completion  # Programmable completion for bash
      tmux             # Terminal multiplexer for managing multiple sessions
    ];

    programs.bash.completion.enable = true;
  };
}

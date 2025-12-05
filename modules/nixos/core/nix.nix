# Nix core settings (flakes + performance)
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.core.nix;
in
{
  options.myModules.nixos.core.nix = {
    maxJobs = lib.mkOption {
      type = lib.types.either lib.types.ints.positive (lib.types.enum ["auto"]);
      default = "auto";
      description = "Maximum number of parallel build jobs";
    };

    cores = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = "Cores per job (0 = all available)";
    };

    enableSandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable build sandboxing for security";
    };
  };

  config = {
    nix.settings = {
      # Modern Nix (always enabled)
      experimental-features = [ "nix-command" "flakes" ];

      # Permissions
      trusted-users = [ "root" "@wheel" ];

      # Developer experience
      warn-dirty = false;

      # Performance
      max-jobs = cfg.maxJobs;
      cores = cfg.cores;

      # Security
      sandbox = cfg.enableSandbox;
    };
  };
}

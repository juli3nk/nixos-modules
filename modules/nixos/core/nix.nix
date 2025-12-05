# Nix configuration (flakes + optimizations)
{ config, lib, ... }:

let
  cfg = config.myModules.nixos.core.nix;
in
{
  options.myModules.nixos.core.nix = {
    gc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic garbage collection";
      };
      
      frequency = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "GC frequency (systemd calendar format)";
        example = "daily";
      };
      
      olderThan = lib.mkOption {
        type = lib.types.str;
        default = "30d";
        description = "Delete generations older than this";
        example = "7d";
      };
    };
    
    autoOptimise = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically deduplicate store";
    };
    
    maxJobs = lib.mkOption {
      type = lib.types.either lib.types.ints.positive (lib.types.enum ["auto"]);
      default = "auto";
      description = "Maximum number of parallel build jobs";
    };
  };

  config = {
    nix = {
      settings = {
        # Modern Nix (always enabled)
        experimental-features = [ "nix-command" "flakes" ];
        
        # Permissions
        trusted-users = [ "root" "@wheel" ];
        
        # Developer experience
        warn-dirty = false;
        
        # Performance
        auto-optimise-store = cfg.autoOptimise;
        max-jobs = cfg.maxJobs;
        cores = 0; # Use all available cores
        
        # Build sandbox
        sandbox = true;
      };

      # Garbage collection
      gc = lib.mkIf cfg.gc.enable {
        automatic = true;
        dates = cfg.gc.frequency;
        options = "--delete-older-than ${cfg.gc.olderThan}";
      };
      
      # Optimise on every build (alternative to auto-optimise-store)
      optimise.automatic = cfg.autoOptimise;
    };
  };
}


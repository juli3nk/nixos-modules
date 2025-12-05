# Cross-compilation support via binfmt emulation
# Enables building packages for other architectures (ARM64, RISC-V, etc.)
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.system.crossCompilation;
in
{
  options.myModules.nixos.features.system.crossCompilation = {
    enable = lib.mkEnableOption "cross-compilation support";

    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "aarch64-linux" ];
      description = ''
        List of systems to emulate for cross-compilation.
        Common values: aarch64-linux, riscv64-linux, armv7l-linux
      '';
      example = [ "aarch64-linux" "riscv64-linux" ];
    };

    installQemu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install QEMU user-space emulation tools";
    };

    enableCache = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use binary cache for cross-compiled packages";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable binfmt emulation
    boot.binfmt.emulatedSystems = cfg.systems;

    # QEMU user-space emulation
    environment.systemPackages = lib.mkIf cfg.installQemu [
      pkgs.qemu
    ];

    # Binary cache for cross-compilation
    nix.settings = lib.mkIf cfg.enableCache {
      substituters = [
        "https://cache.nixos.org"
        # Add ARM-specific caches
        "https://arm.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "arm.cachix.org-1:K3XjAeWPgWkFtSS9ge5LJSLw3xgnNqyOaG7MDecmTQ8="
      ];
    };

    # Documentation
    environment.etc."nixos/cross-compilation.txt".text = ''
      Cross-compilation enabled for: ${lib.concatStringsSep ", " cfg.systems}

      Usage examples:

      # Build for ARM64
      nix build --system aarch64-linux .#myPackage

      # Enter shell for ARM64
      nix develop --system aarch64-linux

      # Build Docker image for ARM64
      nix build .#dockerImage --system aarch64-linux

      # Check available systems
      nix eval --impure --expr 'builtins.currentSystem'
    '';
  };
}

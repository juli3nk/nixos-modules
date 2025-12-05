{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.monitoring;
in
{
  options.myModules.nixos.features.packages.monitoring = {
    enable = lib.mkEnableOption "system monitoring tools";

    level = lib.mkOption {
      type = lib.types.enum [ "basic" "advanced" "full" ];
      default = "basic";
      description = ''
        Monitoring level:
        - basic: htop, procps
        - advanced: + btop, sysstat, iotop
        - full: + glances, procs, tracing tools
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Basic (always installed)
      procps           # Process and system utilities (ps, top, free, vmstat)
      htop             # Interactive process viewer and system monitor
    ] ++ lib.optionals (cfg.level == "advanced" || cfg.level == "full") [
      btop             # Modern resource monitor with GPU and network stats
      sysstat          # System performance monitoring tools
      iotop            # I/O usage monitor showing per-process disk I/O
    ] ++ lib.optionals (cfg.level == "full") [
      glances          # Cross-platform system monitoring tool with web interface
      procs            # Modern process viewer replacement for ps
      strace           # System call tracer for debugging and monitoring
      ltrace           # Library call tracer for dynamic library functions
      bpftrace         # High-level tracing language for Linux eBPF
      lsof             # List open files and network connections by process
    ];
  };
}

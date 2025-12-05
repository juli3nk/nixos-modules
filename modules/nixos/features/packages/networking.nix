{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.packages.networking;
in
{
  options.myModules.nixos.features.packages.networking = {
    enable = lib.mkEnableOption "networking tools";

    includeDownloaders = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include download utilities (curl, wget, aria2)";
    };

    includeDiagnostics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include diagnostic tools (tcpdump, mtr, iperf3)";
    };

    includeMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include bandwidth monitoring tools (iftop, bmon)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Core networking
      iproute2         # Modern network configuration utilities (ip, ss, tc)
      dnsutils         # DNS utilities (dig, nslookup, host)
      netcat           # Network utility for reading/writing network connections
      socat            # Multipurpose relay and socket utility
    ] ++ lib.optionals cfg.includeDownloaders [
      curl             # Command-line tool for transferring data with URLs
      wget             # Non-interactive network downloader
      aria2            # Lightweight multi-protocol download utility
    ] ++ lib.optionals cfg.includeDiagnostics [
      mtr              # Network diagnostic tool combining traceroute and ping
      gping            # Interactive ping tool with real-time graph
      iperf3           # Network bandwidth measurement and testing tool
      tcpdump          # Network packet analyzer
      speedtest-cli    # Command-line interface for internet speed testing
      inetutils        # Network utilities (telnet, ftp, etc.)
    ] ++ lib.optionals cfg.includeMonitoring [
      bmon             # Bandwidth utilization monitor
      iftop            # Interactive network bandwidth monitor
    ];
  };
}

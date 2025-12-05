{ config, lib, ... }:

let
  cfg = config.myModules.nixos.services.prometheus.nodeExporter;
in
{
  options.myModules.nixos.services.prometheus.nodeExporter = {
    enable = lib.mkEnableOption "Prometheus node exporter for system metrics";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the metrics endpoint";
      example = "0.0.0.0";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9100;
      description = "Port for the metrics endpoint";
    };

    collectors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "systemd" ];
      description = ''
        Collectors enabled in addition to the defaults.
        See: https://github.com/prometheus/node_exporter#collectors
      '';
      example = [ "systemd" "processes" "tcpstat" ];
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional
      (cfg.listenAddress == "0.0.0.0")
      ''
        ⚠️  Node Exporter is listening on all network interfaces (0.0.0.0:${toString cfg.port}).

        This exposes system metrics to your entire network.

        Recommended security measures:

        1. If Prometheus runs on the same host (localhost scraping):
          → Set listenAddress = "127.0.0.1" instead

        2. If Prometheus runs in a container using host.containers.internal:
          → Keep 0.0.0.0 BUT add firewall rules to restrict access:

        3. If Prometheus scrapes from another host:
          → Consider using a VPN or SSH tunnel
          → Or use firewall rules to allow specific IPs only
      '';

    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = cfg.listenAddress;
      port = cfg.port;
      enabledCollectors = cfg.collectors;
    };
  };
}

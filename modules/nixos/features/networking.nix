{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.networking;

  interfaces = [
    "ve-*"      # systemd-nspawn
    "veth*"     # veth pairs
  ];

  # Helper function to create systemd-networkd network configuration
  mkNetworkConfig = {
    # Match configuration (either Type or Name)
    match ? null
  , name ? null
  # Network configuration options
  , enableIPv6 ? cfg.enableIPv6
  , dhcp ? null  # null = no DHCP, true/false = DHCP enabled/disabled, or "yes"/"ipv4" string
  , address ? null
  , gateway ? null
  , dnsMode ? cfg.dns.mode
  , dnsServers ? cfg.dns.nameservers
  # DHCP configuration
  , routeMetric ? 100
  # Link configuration
  , requiredForOnline ? "routable"
  # Additional network config (e.g., LinkLocalAddressing)
  , extraNetworkConfig ? {}
  }:
    let
      matchConfig = if match != null then { Type = match; } else { Name = name; };
      dhcpValue = if dhcp == null then null
                  else if builtins.isString dhcp then dhcp
                  else if dhcp then (if enableIPv6 then "yes" else "ipv4")
                  else null;
    in
    {
      matchConfig = matchConfig;
      networkConfig = lib.mkMerge [
        {
          IPv6AcceptRA = enableIPv6;
        }
        extraNetworkConfig
        (lib.mkIf (dhcpValue != null) {
          DHCP = dhcpValue;
        })
        (lib.mkIf (address != null) {
          Address = [ address ];
        })
        (lib.mkIf (gateway != null) {
          Gateway = gateway;
        })
        (lib.mkIf (dnsMode != "dhcp") {
          DNS = dnsServers;
        })
      ];
      dhcpV4Config = lib.mkIf (dhcpValue != null) {
        RouteMetric = routeMetric;
        UseDNS = dnsMode == "dhcp";
      };
      dhcpV6Config = lib.mkIf enableIPv6 {
        UseDNS = dnsMode == "dhcp";
      };
      linkConfig.RequiredForOnline = requiredForOnline;
    };
in
{
  options.myModules.nixos.features.networking = {
    backend = lib.mkOption {
      type = lib.types.enum [ "networkmanager" "systemd-networkd" "static" ];
      default = "networkmanager";
      description = ''
        Network backend to use:
        - networkmanager: Desktop/laptop, good for WiFi and dynamic networks
        - systemd-networkd: Servers, lightweight and reliable
        - static: Manual configuration via networking.interfaces
      '';
    };

    enableIPv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IPv6 support";
    };

    bridges = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          interfaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Physical interfaces to bridge";
            example = [ "enp0s25" "enp1s0" ];
          };

          dhcp = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Use DHCP on this bridge";
          };

          address = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Static IP address (CIDR notation)";
            example = "192.168.1.10/24";
          };

          gateway = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Default gateway for static config";
            example = "192.168.1.1";
          };

          rstp = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Rapid Spanning Tree Protocol";
          };
        };
      });
      default = {};
      description = "Bridge configurations";
      example = {
        br0 = {
          interfaces = [ "enp0s25" ];
          dhcp = true;
        };
      };
    };

    wifi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable WiFi support";
      };

      useIwd = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use iwd instead of wpa_supplicant (more modern)";
      };
    };

    dns = {
      mode = lib.mkOption {
        type = lib.types.enum [ "dhcp" "static" "resolved" ];
        default = "resolved";
        description = ''
          DNS resolution mode:
          - dhcp: Use DNS from DHCP (NetworkManager default)
          - static: Use manually configured nameservers
          - resolved: Use systemd-resolved with fallback DNS
        '';
      };

      nameservers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "1.1.1.1" "1.0.0.1" ];
        description = "DNS nameservers (used in static or resolved mode)";
        example = [ "192.168.1.1" "1.1.1.1" ];
      };

      fallbackServers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "8.8.8.8" "8.8.4.4" ];
        description = "Fallback DNS servers for resolved mode";
      };

      enableDNSSEC = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable DNSSEC validation (resolved mode only)";
      };

      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "DNS search domains";
        example = [ "local" "lan" ];
      };
    };
  };

  config = lib.mkMerge [
    # Common settings
    {
      # Enable WiFi hardware support
      networking.wireless.enable = lib.mkIf
        (cfg.wifi.enable && !cfg.wifi.useIwd && cfg.backend != "networkmanager")
        true;
    }

    # Disable IPv6 globally if requested
    (lib.mkIf (!cfg.enableIPv6) {
      boot.kernelParams = [ "ipv6.disable=1" ];
      networking.enableIPv6 = false;
    })

    # Bridge Configuration
    # Note: rstp is not supported by systemd-networkd
    (lib.mkIf (cfg.bridges != {}) {
      networking.bridges = lib.mapAttrs (name: bridgeCfg: {
        interfaces = bridgeCfg.interfaces;
        rstp = if cfg.backend == "systemd-networkd" then false else bridgeCfg.rstp;
      }) cfg.bridges;
    })

    # iwd manages WiFi connection only
    (lib.mkIf (cfg.wifi.enable && cfg.wifi.useIwd) {
      networking.wireless.iwd = {
        enable = true;
        settings = {
          General = {
            EnableNetworkConfiguration = false; # network backend handles DHCP
            RoamRetryInterval = 15;
          };
          Network = {
            EnableIPv6 = cfg.enableIPv6;
          };
          Settings = {
            AutoConnect = true;
          };
          Scan = {
            DisablePeriodicScan = false;
            InitialPeriodicScanInterval = 300; # Scan every 5min if disconnected
            MaxPeriodicScanInterval = 300;
            DisableRoamingScan = true;         # No AP roaming
          };
          DriverQuirks = {
            UseDefaultInterface = true;
          };
        };
      };
    })

    # DNS Configuration
    # Mode: DHCP (NetworkManager manages DNS)
    (lib.mkIf (cfg.dns.mode == "dhcp" && cfg.backend == "networkmanager") {
      networking.networkmanager.dns = "default";
      services.resolved.enable = false;
    })

    # Mode: systemd-resolved (with fallback DNS)
    (lib.mkIf (cfg.dns.mode == "resolved") {
      services.resolved = {
        enable = true;
        dnssec = if cfg.dns.enableDNSSEC then "allow-downgrade" else "false";
        fallbackDns = cfg.dns.fallbackServers;
        domains = cfg.dns.domains;
      };

      # NetworkManager uses systemd-resolved
      networking.networkmanager.dns = lib.mkIf (cfg.backend == "networkmanager") "systemd-resolved";

      # Configure nameservers for resolved
      networking.nameservers = cfg.dns.nameservers;
    })

    # Mode: Static DNS (pure static, no resolved)
    (lib.mkIf (cfg.dns.mode == "static") {
      services.resolved.enable = false;

      # NetworkManager doesn't manage DNS
      networking.networkmanager.dns = lib.mkIf (cfg.backend == "networkmanager") "none";

      # Static nameservers
      networking.nameservers = cfg.dns.nameservers;
      networking.search = cfg.dns.domains;

      # Enable resolvconf for static DNS
      networking.resolvconf.enable = true;
    })

    # NetworkManager (laptops/desktops)
    (lib.mkIf (cfg.backend == "networkmanager") {
      networking.networkmanager = {
        enable = true;

        wifi.backend = if cfg.wifi.useIwd then "iwd" else "wpa_supplicant";

        # WiFi privacy
        wifi.scanRandMacAddress = lib.mkDefault true;
      };

      networking.wireless.enable = false;
      networking.useNetworkd = false;
      networking.useDHCP = false;

      # Don't manage virtual interfaces (containers, VMs, Docker) and bridges
      networking.networkmanager.unmanaged = lib.mkAfter (
        (map (iface: "interface-name:${iface}") interfaces)
        ++ lib.optionals (cfg.bridges != {})
          (lib.mapAttrsToList (name: _: "interface-name:${name}") cfg.bridges)
      );
    })

    # Bridge IP configuration - NetworkManager and Static
    (lib.mkIf (
      (cfg.backend == "networkmanager" || cfg.backend == "static")
      && cfg.bridges != {}
    ) {
      networking.interfaces = lib.mapAttrs (name: bridgeCfg: {
        useDHCP = bridgeCfg.dhcp;
        ipv4.addresses = lib.optional (bridgeCfg.address != null) {
          address = lib.head (lib.splitString "/" bridgeCfg.address);
          prefixLength = lib.toInt (lib.last (lib.splitString "/" bridgeCfg.address));
        };
      }) cfg.bridges;

      # Gateway configuration (use first bridge with a gateway)
      networking.defaultGateway = lib.mkIf (
        let
          bridgesWithGateway = lib.filterAttrs (_: v: v.gateway != null) cfg.bridges;
        in
        bridgesWithGateway != {}
      ) {
        address = (lib.head (lib.attrValues (lib.filterAttrs (_: v: v.gateway != null) cfg.bridges))).gateway;
      };
    })

    # systemd-networkd (servers)
    (lib.mkIf (cfg.backend == "systemd-networkd") {
      systemd.network.enable = true;

      networking.networkmanager.enable = false;
      networking.useNetworkd = true;
      networking.useDHCP = false;

      systemd.network.networks = lib.mkMerge [
        # networkd manages DHCP on WiFi
        (lib.mkIf cfg.wifi.enable {
          "40-wireless" = mkNetworkConfig {
            match = "wlan";
            dhcp = true;
            extraNetworkConfig = {
              LinkLocalAddressing = if cfg.enableIPv6 then "yes" else "ipv4";
            };
            routeMetric = 100;
          };
        })

        # Bridge IP configuration - systemd-networkd
        (lib.mkIf (cfg.bridges != {})
          (lib.listToAttrs (
            lib.mapAttrsToList (name: bridgeCfg: {
              name = "50-${name}";
              value = mkNetworkConfig {
                name = name;
                dhcp = bridgeCfg.dhcp;
                address = bridgeCfg.address;
                gateway = bridgeCfg.gateway;
                routeMetric = 50; # Higher priority than WiFi
              };
            }) cfg.bridges
          )))

        # Ignore container/VM interfaces and bridges
        {
          "60-interfaces-ignore" = {
            matchConfig.Name = lib.concatStringsSep " " (
              interfaces
              ++ lib.optionals (cfg.bridges != {})
                (lib.mapAttrsToList (name: _: name) cfg.bridges)
            );
            linkConfig.Unmanaged = true;
          };
        }
      ];
    })

    # Static/manual configuration
    (lib.mkIf (cfg.backend == "static") {
      networking.networkmanager.enable = false;
      networking.useNetworkd = false;
      networking.useDHCP = false;
    })

    # Wireless tools
    (lib.mkIf cfg.wifi.enable {
      environment.systemPackages = with pkgs; [
        iw
        wirelesstools
      ] ++ lib.optional cfg.wifi.useIwd pkgs.iwd;
    })
  ];
}

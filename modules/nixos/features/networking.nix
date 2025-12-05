{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.networking;

  virtualInterfaces = [
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
  , aliases ? []
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
      matchConfig = if match != null then { Type = match; }
                    else { Name = name; };
      dhcpValue = if dhcp == null then null
                  else if builtins.isString dhcp then dhcp
                  else if dhcp then (if enableIPv6 then "yes" else "ipv4")
                  else null;
      # Combine primary address and aliases into a single Address list
      allAddresses = lib.optionals (address != null) [ address ] ++ aliases;
    in
    {
      matchConfig = matchConfig;

      networkConfig = lib.mkMerge [
        {
          IPv6AcceptRA = enableIPv6;
        }
        extraNetworkConfig
        (lib.mkIf (dhcpValue != null) {
          DHCP = lib.mkForce dhcpValue;
        })
        (lib.mkIf (allAddresses != []) {
          Address = allAddresses;
        })
        (lib.mkIf (gateway != null) {
          Gateway = gateway;
        })
        (lib.mkIf (dnsMode != "dhcp" && dnsServers != []) {
          DNS = dnsServers;
        })
      ];

      dhcpV4Config = lib.mkIf (dhcpValue != null) {
        RouteMetric = routeMetric;
        UseDNS = dnsMode == "dhcp";
      };

      dhcpV6Config = lib.mkIf (enableIPv6 && dhcpValue != null) {
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

    interfaces = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          dhcp = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Use DHCP on this interface";
          };

          address = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Static IP address (CIDR notation)";
            example = "192.168.1.10/24";
          };

          aliases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional alias IP addresses (CIDR notation)";
            example = [ "192.168.0.2/24" "192.168.0.3/24" ];
          };

          gateway = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Default gateway for static config";
            example = "192.168.1.1";
          };
        };
      });
      default = {};
      description = "Interface configurations";
      example = {
        wlan0 = {
          dhcp = true;
        };
      };
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

          aliases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional alias IP addresses (CIDR notation)";
            example = [ "192.168.0.2/24" "192.168.0.3/24" ];
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

    dns = {
      mode = lib.mkOption {
        type = lib.types.enum [ "dhcp" "resolved" "static" ];
        default = if cfg.backend == "systemd-networkd" then "resolved" else "dhcp";
        description = ''
          DNS resolution mode:
          - dhcp: Pure DHCP (automatic from network)
          - resolved: systemd-resolved (recommended for systemd-networkd, supports cache/DNSSEC)
          - static: Static configuration via resolvconf (not recommended with systemd-networkd)
        '';
      };

      nameservers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = [ "192.168.1.1" ];
        description = "Primary DNS servers (ignored in pure dhcp mode)";
      };

      fallbackServers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "1.1.1.1" "1.0.0.1" ];
        description = "Fallback DNS servers (resolved mode only)";
      };

      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = [ "local" "example.com" ];
        description = "DNS search domains";
      };

      enableDNSSEC = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable DNSSEC validation (resolved mode only)";
      };

      enableCache = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable DNS caching (resolved mode only)";
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

      networking.interfaces = lib.mapAttrs (name: intfCfg: {
        useDHCP = intfCfg.dhcp;
        ipv4.addresses = lib.optional (intfCfg.address != null) {
          address = lib.head (lib.splitString "/" intfCfg.address);
          prefixLength = lib.toInt (lib.last (lib.splitString "/" intfCfg.address));
        };
      }) cfg.interfaces;

      # Don't manage virtual interfaces (containers, VMs, Docker) and bridges
      networking.networkmanager.unmanaged = lib.mkAfter (
        (map (iface: "interface-name:${iface}") virtualInterfaces)
        ++ lib.optionals (cfg.interfaces != {})
          (lib.mapAttrsToList (name: _: "interface-name:${name}") cfg.interfaces)
        ++ lib.optionals (cfg.bridges != {})
          (lib.mapAttrsToList (name: _: "interface-name:${name}") cfg.bridges)
      );
    })

    # systemd-networkd (servers)
    (lib.mkIf (cfg.backend == "systemd-networkd") {
      systemd.network.enable = true;

      networking.networkmanager.enable = false;
      networking.useNetworkd = true;
      networking.useDHCP = false;

      systemd.network.networks = lib.mkMerge [
        # Interface IP configuration
        (lib.mkIf (cfg.interfaces != {})
          (lib.listToAttrs (
            lib.mapAttrsToList (name: intfCfg:
              let
                # Construire l'attrset de paramètres AVANT l'appel à mkNetworkConfig
                baseConfig = {
                  name = name;
                  dhcp = intfCfg.dhcp;
                  routeMetric = 100;
                  extraNetworkConfig = {
                    LinkLocalAddressing = if cfg.enableIPv6 then "yes" else "ipv4";
                  };
                };

                # Ajouter conditionnellement address, aliases, gateway
                finalConfig = baseConfig
                  // lib.optionalAttrs (!intfCfg.dhcp && intfCfg.address != null) {
                    address = intfCfg.address;
                  }
                  // lib.optionalAttrs (intfCfg.aliases != []) {
                    aliases = intfCfg.aliases;
                  }
                  // lib.optionalAttrs (intfCfg.gateway != null) {
                    gateway = intfCfg.gateway;
                  };
              in
              {
                name = "40-${name}";
                value = mkNetworkConfig finalConfig;
              }
            ) cfg.interfaces
          )))


        # Bridge IP configuration
        (lib.mkIf (cfg.bridges != {})
          (lib.listToAttrs (
            lib.mapAttrsToList (name: bridgeCfg:
              let
                # Build the parameter attrset BEFORE calling mkNetworkConfig
                baseConfig = {
                  name = name;
                  dhcp = bridgeCfg.dhcp;
                  routeMetric = 50; # Higher priority than WiFi
                  requiredForOnline = "no";
                  extraNetworkConfig = {
                    LinkLocalAddressing = "no";
                    ConfigureWithoutCarrier = "yes";
                  };
                };

                # Conditionally add address and gateway
                finalConfig = baseConfig
                  // lib.optionalAttrs (!bridgeCfg.dhcp && bridgeCfg.address != null) {
                    address = bridgeCfg.address;
                  }
                  // lib.optionalAttrs (bridgeCfg.aliases != []) {
                    aliases = bridgeCfg.aliases;
                  }
                  // lib.optionalAttrs (bridgeCfg.gateway != null) {
                    gateway = bridgeCfg.gateway;
                  };
              in
              {
                name = "50-${name}";
                value = mkNetworkConfig finalConfig;
              }
            ) cfg.bridges
          )))

        # Ignore container/VM interfaces and bridges
        {
          "60-interfaces-ignore" = {
            matchConfig.Name = lib.concatStringsSep " " (
              virtualInterfaces
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

    # Bridge Configuration
    # Note: rstp is not supported by systemd-networkd
    (lib.mkIf (cfg.bridges != {}) {
      networking.bridges = lib.mapAttrs (name: bridgeCfg: {
        interfaces = bridgeCfg.interfaces;
        rstp = if cfg.backend == "systemd-networkd" then false else bridgeCfg.rstp;
      }) cfg.bridges;
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

    # DNS Configuration
    # Mode: DHCP - Pure automatic DNS from DHCP
    (lib.mkIf (cfg.dns.mode == "dhcp") {
      # NetworkManager backend
      networking.networkmanager.dns = lib.mkIf (cfg.backend == "networkmanager") "default";

      # systemd-networkd backend: UseDNS=true will be set in .network files
      # No additional config needed here

      # Disable resolved and resolvconf in pure DHCP mode
      services.resolved.enable = false;
      networking.resolvconf.enable = lib.mkDefault false;
    })

    # Mode: systemd-resolved - Intelligent DNS with cache, DNSSEC, split-DNS
    (lib.mkIf (cfg.dns.mode == "resolved") {
      services.resolved = {
        enable = true;
        dnssec = if cfg.dns.enableDNSSEC then "true" else "false";

        # DNS servers configuration
        domains = cfg.dns.domains;
        fallbackDns = cfg.dns.fallbackServers;

        extraConfig = ''
          ${lib.optionalString (!cfg.dns.enableCache) "Cache=no"}
          DNSStubListener=yes
        '';
      };

      # NetworkManager: use resolved as backend
      networking.networkmanager.dns = lib.mkIf (cfg.backend == "networkmanager") "systemd-resolved";

      # Static nameservers passed to resolved
      networking.nameservers = lib.mkIf (cfg.dns.nameservers != []) cfg.dns.nameservers;

      # Disable resolvconf (resolved manages /etc/resolv.conf)
      networking.resolvconf.enable = false;
    })

    # Mode: Static - Traditional static DNS via resolvconf
    (lib.mkIf (cfg.dns.mode == "static") {
      # Warning for systemd-networkd users
      warnings = lib.optional (cfg.backend == "systemd-networkd") ''
        Using dns.mode = "static" with systemd-networkd is not recommended.
        Consider using dns.mode = "resolved" instead for better integration.
      '';

      services.resolved.enable = false;

      # NetworkManager: disable DNS management
      networking.networkmanager.dns = lib.mkIf (cfg.backend == "networkmanager") "none";

      # Static nameservers
      networking.nameservers = cfg.dns.nameservers;
      networking.search = cfg.dns.domains;

      # Enable resolvconf only if NOT using systemd-networkd
      networking.resolvconf.enable = (cfg.backend != "systemd-networkd");

      # For systemd-networkd in static mode: DNS will be set in .network files
      # and networkd will manage resolv.conf directly (suboptimal but functional)
    })

    # Additional assertions
    {
      assertions = [
        {
          assertion = cfg.dns.mode != "dhcp" || cfg.dns.nameservers == [];
          message = "dns.nameservers are ignored when dns.mode = \"dhcp\"";
        }
        {
          assertion = cfg.dns.mode == "resolved" || !cfg.dns.enableDNSSEC;
          message = "dns.enableDNSSEC only works with dns.mode = \"resolved\"";
        }
        {
          assertion = cfg.dns.mode == "resolved" || cfg.dns.fallbackServers == [ "1.1.1.1" "1.0.0.1" ];
          message = "dns.fallbackServers only works with dns.mode = \"resolved\"";
        }
      ];
    }

    # Wireless tools
    (lib.mkIf cfg.wifi.enable {
      environment.systemPackages = with pkgs; [
        iw
        wirelesstools
      ] ++ lib.optional cfg.wifi.useIwd pkgs.iwd;
    })
  ];
}

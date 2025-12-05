# Base networking configuration
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.networking;

  interfaces = [
    "ve-*"      # systemd-nspawn
    "veth*"     # veth pairs
    "br-*"      # Custom bridges
  ];
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
    
    wifi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable WiFi support";
      };
      
      useIwd = lib.mkOption {
        type = lib.types.bool;
        default = cfg.backend == "networkmanager";
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
        
        # Don't manage virtual interfaces (containers, VMs, Docker)
        unmanaged = lib.mkAfter (
          map (iface: "interface-name:${iface}") interfaces
        );

        wifi.backend = if cfg.wifi.useIwd then "iwd" else "wpa_supplicant";

        # WiFi privacy
        wifi.scanRandMacAddress = lib.mkDefault true;
      };

      networking.wireless.enable = false;
      networking.useNetworkd = false;
      networking.useDHCP = false;
    })

    # systemd-networkd (servers)
    (lib.mkIf (cfg.backend == "systemd-networkd") {
      systemd.network.enable = true;

      networking.networkmanager.enable = false;
      networking.useNetworkd = true;
      networking.useDHCP = false;
      
      systemd.network.networks."50-interfaces-ignore" = {
        matchConfig.Name = lib.concatStringsSep " " interfaces;
        linkConfig.Unmanaged = true;
      };

      # iwd for modern WiFi support on servers
      networking.wireless.iwd.enable = lib.mkIf (cfg.wifi.enable && cfg.wifi.useIwd) true;
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
      ];
    })
  ];
}

{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.virtualisation.docker;

  hasNetworkManager = config.networking.networkmanager.enable;
  hasNetworkd = config.networking.useNetworkd;
  
  interfaces = [ "docker*" ];
in
{
  options.myModules.nixos.features.virtualisation.docker = {
    enable = lib.mkEnableOption "Enable Docker" // { default = true; };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Basic Docker configuration
    {
      virtualisation.docker = {
        enableOnBoot = lib.mkDefault true;
        liveRestore = lib.mkDefault false;
        extraOptions = "--iptables=true --experimental";
      };

      networking.firewall.trustedInterfaces = [ "docker0" ];
    }

    # NetworkManager configuration (if enabled)
    (lib.mkIf hasNetworkManager {
      networking.networkmanager.unmanaged = lib.mkAfter (
        map (iface: "interface-name:${iface}") interfaces
      );
    })

    # systemd-networkd configuration (if enabled)
    (lib.mkIf hasNetworkd {
      systemd.network.networks."51-docker-ignore" = {
        matchConfig.Name = lib.concatStringsSep " " interfaces;
        linkConfig.Unmanaged = true;
      };
    })
  ]);
}

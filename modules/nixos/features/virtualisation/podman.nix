{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.virtualisation.podman;

  hasNetworkManager = config.networking.networkmanager.enable;
  hasNetworkd = config.networking.useNetworkd;

  interfaces = [
    "podman*"
    "cni-*"
  ];
in
{
  options.myModules.nixos.features.virtualisation.podman = {
    enable = lib.mkEnableOption "Enable Podman";
    enableDockerCompat = lib.mkEnableOption "Enable Docker compatibility layer" // { default = true; };
    enableRootless = lib.mkEnableOption "Configure rootless containers" // { default = true; };
  };

  config = lib.mkMerge [
    # Basic configuration
    {
      virtualisation.podman = {
        enable = cfg.enable;

        dockerCompat = cfg.enableDockerCompat;
        dockerSocket.enable = cfg.enableDockerCompat;

        defaultNetwork.settings.dns_enabled = true;

        autoPrune = {
          enable = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          flags = [ "--all" ];
        };
      };
    }

    # NetworkManager configuration
    (lib.mkIf hasNetworkManager {
      networking.networkmanager.unmanaged = lib.mkAfter (
        map (iface: "interface-name:${iface}") interfaces
      );
    })

    # systemd-networkd configuration
    (lib.mkIf hasNetworkd {
      systemd.network.networks."51-podman-ignore" = {
        matchConfig.Name = lib.concatStringsSep " " interfaces;
        linkConfig.Unmanaged = true;
      };
    })

    # Rootless configuration
    (lib.mkIf cfg.enableRootless {
      users.users.${config.mySystem.user} = {
        subUidRanges = [{ startUid = 100000; count = 65536; }];
        subGidRanges = [{ startGid = 100000; count = 65536; }];
      };
    })
  ];
}

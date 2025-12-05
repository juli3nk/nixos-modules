{ config, lib, ... }:

let
  cfg = config.myModules.nixos.features.virtualisation.docker;

  hasNetworkManager = config.networking.networkmanager.enable;
  hasNetworkd = config.networking.useNetworkd;
in
{
  options.myModules.nixos.features.virtualisation.docker = {
    enable = lib.mkEnableOption "Enable Docker";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users to add to the docker group";
      example = [ "alice" "bob" ];
    };

    networkInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "docker*" ];
      description = "docker network interfaces to ignore";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Basic Docker configuration
    {
      virtualisation.docker = {
        enable = cfg.enable;
        # enableOnBoot = lib.mkDefault true;
        liveRestore = lib.mkDefault false;
        extraOptions = "--iptables=true --experimental";
      };

      # networking.firewall.trustedInterfaces = [ "docker0" ];
    }

    # NetworkManager configuration (if enabled)
    (lib.mkIf hasNetworkManager {
      networking.networkmanager.unmanaged = lib.mkAfter (
        map (iface: "interface-name:${iface}") cfg.networkInterfaces
      );
    })

    # systemd-networkd configuration (if enabled)
    (lib.mkIf hasNetworkd {
      systemd.network.networks."51-docker-ignore" = {
        matchConfig.Name = lib.concatStringsSep " " cfg.networkInterfaces;
        linkConfig.Unmanaged = true;
      };
    })

    # User management
    (lib.mkIf (cfg.users != []) {
      users.users = lib.mkMerge (
        map (username: {
          ${username}.extraGroups = [ "docker" ];
        }) cfg.users
      );
    })
  ]);
}

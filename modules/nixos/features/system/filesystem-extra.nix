# Optional filesystem support: ZFS, network shares, LVM, niche filesystems
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.system.filesystemExtra;
in
{
  options.myModules.nixos.features.system.filesystemExtra = {
    enable = lib.mkEnableOption "extended filesystem support (ZFS, network shares, LVM)";

    includeLVM = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include LVM tools";
    };

    includeBtrfs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include btrfs support and tools";
    };

    includeXfs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include XFS support and tools";
    };

    includeF2fs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include F2FS filesystem support";
    };

    enableNetworkShares = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable CIFS/SMB (Windows shares) and NFS support";
    };

    enableZfs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable ZFS support.
        Warning: ZFS is not GPL-compatible, requires accepting license.
        Requires networking.hostId to be set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.enableZfs || config.networking.hostId != null;
        message = "filesystemExtra: ZFS requires networking.hostId to be set.";
      }
    ];

    boot.supportedFilesystems = lib.optional cfg.includeF2fs "f2fs"
      ++ lib.optional cfg.enableNetworkShares "cifs"
      ++ lib.optional cfg.enableNetworkShares "nfs"
      ++ lib.optional cfg.enableZfs "zfs";

    boot.zfs = lib.mkIf cfg.enableZfs {
      forceImportRoot = false;
      forceImportAll = false;
    };

    services.rpcbind.enable = cfg.enableNetworkShares;

    environment.systemPackages =
      lib.optional cfg.includeLVM pkgs.lvm2
      ++ lib.optional cfg.includeBtrfs pkgs.btrfs-progs
      ++ lib.optional cfg.includeXfs pkgs.xfsprogs
      ++ lib.optional cfg.includeF2fs pkgs.f2fs-tools
      ++ lib.optional cfg.enableNetworkShares pkgs.cifs-utils
      ++ lib.optional cfg.enableNetworkShares pkgs.nfs-utils
      ++ lib.optional cfg.enableZfs pkgs.zfs;
  };
}

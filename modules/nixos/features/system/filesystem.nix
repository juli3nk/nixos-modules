# Extended filesystem support for removable media and network shares
# Enables mounting various filesystems beyond the base system
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.system.filesystemSupport;
in
{
  options.myModules.nixos.features.system.filesystemSupport = {
    enable = lib.mkEnableOption "extended filesystem support";

    filesystems = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "ext4"
        "btrfs"
        "xfs"
        "f2fs"
        "ntfs"
        "exfat"
        "fat"
      ]);
      default = [
        "ext4"
        "btrfs"
        "xfs"
        "ntfs"
        "exfat"
        "fat"
      ];
      description = "List of filesystems to support";
    };

    includeLVM = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include LVM tools";
    };

    enableNetworkShares = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable CIFS/SMB (Windows shares) and NFS support";
    };

    enableFuse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable FUSE (Filesystem in Userspace) support";
    };

    enableZfs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable ZFS support.
        Warning: ZFS is not GPL-compatible, requires accepting license.
      '';
    };

    installTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install filesystem management tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # Base filesystem support
    boot.supportedFilesystems = cfg.filesystems
      ++ lib.optional cfg.enableFuse "fuse3"
      ++ lib.optional cfg.enableNetworkShares "cifs"
      ++ lib.optional cfg.enableNetworkShares "nfs"
      ++ lib.optional cfg.enableZfs "zfs";

    # ZFS specific configuration
    boot.zfs = lib.mkIf cfg.enableZfs {
      forceImportRoot = false;
      forceImportAll = false;
    };

    # Network shares support
    services.rpcbind.enable = lib.mkIf cfg.enableNetworkShares true; # For NFS

    # Filesystem tools
    environment.systemPackages = lib.mkIf cfg.installTools (
      with pkgs; [
        # Basic tools
        parted
        gptfdisk

        # Filesystem-specific tools
      ] ++ lib.optional cfg.includeLVM lvm2
        ++ lib.optional (builtins.elem "ext4" cfg.filesystems) e2fsprogs
        ++ lib.optional (builtins.elem "btrfs" cfg.filesystems) btrfs-progs
        ++ lib.optional (builtins.elem "xfs" cfg.filesystems) xfsprogs
        ++ lib.optional (builtins.elem "ntfs" cfg.filesystems) ntfs3g
        ++ lib.optional (builtins.elem "fat" cfg.filesystems) dosfstools
        ++ lib.optional (builtins.elem "exfat" cfg.filesystems) exfat
        ++ lib.optional cfg.enableNetworkShares cifs-utils
        ++ lib.optional cfg.enableNetworkShares nfs-utils
        ++ lib.optional cfg.enableZfs zfs
    );
  };
}

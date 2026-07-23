# Base filesystem support for common local and removable media formats
{ config, lib, pkgs, ... }:

{
  boot.supportedFilesystems = [
    "ext4"
    "ntfs"
    "exfat"
    "fat"
    "fuse3"
  ];

  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    e2fsprogs
    ntfs3g
    dosfstools
    exfatprogs
  ];
}

{ ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 10;
    "vm.vfs_cache_pressure" = lib.mkDefault 50;
    "vm.dirty_ratio" = lib.mkDefault 10;
    "vm.dirty_background_ratio" = lib.mkDefault 5;
  };
}

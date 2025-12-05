# Enable Libvirt(QEMU/KVM) with automatic CPU detection
{ config, lib, pkgs, ... }:

let
  hasNetworkManager = config.networking.networkmanager.enable;
  hasNetworkd = config.networking.useNetworkd;
  
  interfaces = [ "virbr*" ];
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = true;
  };

  # Automatic detection and configuration
  boot.kernelModules = lib.mkMerge [
    (lib.mkIf (config.hardware.cpu.intel.updateMicrocode or false) [ "kvm-intel" ])
    (lib.mkIf (config.hardware.cpu.amd.updateMicrocode or false) [ "kvm-amd" ])
  ];

  boot.extraModprobeConfig = lib.mkMerge [
    (lib.mkIf (config.hardware.cpu.intel.updateMicrocode or false) 
      "options kvm_intel nested=1")
    (lib.mkIf (config.hardware.cpu.amd.updateMicrocode or false) 
      "options kvm_amd nested=1")
  ];

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
    qemu_kvm
    qemu_full
  ];

  # NetworkManager configuration
  networking.networkmanager.unmanaged = lib.mkIf hasNetworkManager (
    lib.mkAfter (
      map (iface: "interface-name:${iface}") interfaces
    )
  );

  # systemd-networkd configuration
  systemd.network.networks."51-libvirt-ignore" = lib.mkIf hasNetworkd {
    matchConfig.Name = lib.concatStringsSep " " interfaces;
    linkConfig.Unmanaged = true;
  };
}

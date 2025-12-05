# Libvirt(QEMU/KVM)
{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.virtualisation.libvirtd;

  # Automatic CPU detection
  hasIntelCPU = config.hardware.cpu.intel.updateMicrocode or false;
  hasAmdCPU = config.hardware.cpu.amd.updateMicrocode or false;

  # Network configuration detection
  hasNetworkManager = config.networking.networkmanager.enable;
  hasNetworkd = config.networking.useNetworkd;

in
{
  options.myModules.nixos.features.virtualisation.libvirtd = {
    enable = lib.mkEnableOption "libvirtd extended configuration";

    role = lib.mkOption {
      type = lib.types.enum [ "server" "client" "both" ];
      default = "both";
      description = ''
        Role of this machine:
        - server: hosts VMs
        - client: connects remotely
        - both: both
      '';
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users to add to the libvirtd and kvm groups";
      example = [ "alice" "bob" ];
    };

    server = {
      qemuPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.qemu_kvm;
        description = "QEMU package to use";
      };

      runAsRoot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run QEMU as root (less secure)";
      };

      enableOVMF = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable UEFI support (OVMF)";
      };

      enableTPM = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TPM support (swtpm)";
      };

      enableNested = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable nested virtualization";
      };

      onBoot = lib.mkOption {
        type = lib.types.enum [ "start" "ignore" ];
        default = "start";
        description = "Behavior on boot";
      };

      onShutdown = lib.mkOption {
        type = lib.types.enum [ "shutdown" "suspend" ];
        default = "shutdown";
        description = "Behavior on shutdown";
      };

      networkInterfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "virbr*" ];
        description = "Libvirt network interfaces to ignore";
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Additional QEMU configuration";
      };
    };

    client = {
      enableVirtManager = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install virt-manager";
      };

      enableVirtViewer = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install virt-viewer";
      };

      enableSpice = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install SPICE tools";
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional packages for the client";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Common configuration
    {
      programs.dconf.enable = true;
    }

    # SERVER configuration
    (lib.mkIf (cfg.role == "server" || cfg.role == "both") {
      virtualisation.libvirtd = {
        enable = true;
        onBoot = cfg.server.onBoot;
        onShutdown = cfg.server.onShutdown;

        qemu = {
          package = cfg.server.qemuPackage;
          runAsRoot = cfg.server.runAsRoot;
          ovmf.enable = cfg.server.enableOVMF;
          swtpm.enable = cfg.server.enableTPM;

          verbatimConfig = ''
            # Default configuration for remote access
            unix_sock_group = "libvirtd"
            unix_sock_ro_perms = "0777"
            unix_sock_rw_perms = "0770"

            ${cfg.server.extraConfig}
          '';
        };
      };

      # Automatic CPU detection and configuration
      boot.kernelModules = lib.mkMerge [
        (lib.mkIf hasIntelCPU [ "kvm-intel" ])
        (lib.mkIf hasAmdCPU [ "kvm-amd" ])
      ];

      boot.extraModprobeConfig = lib.mkMerge [
        (lib.mkIf (hasIntelCPU && cfg.server.enableNested)
          "options kvm_intel nested=1")
        (lib.mkIf (hasAmdCPU && cfg.server.enableNested)
          "options kvm_amd nested=1")
      ];

      # Network configuration - NetworkManager
      networking.networkmanager.unmanaged = lib.mkIf hasNetworkManager (
        lib.mkAfter (
          map (iface: "interface-name:${iface}") cfg.server.networkInterfaces
        )
      );

      # Network configuration - systemd-networkd
      systemd.network.networks."51-libvirt-ignore" = lib.mkIf hasNetworkd {
        matchConfig.Name = lib.concatStringsSep " " cfg.server.networkInterfaces;
        linkConfig.Unmanaged = true;
      };

      # Base server packages
      environment.systemPackages = with pkgs; [
        qemu_kvm
        libvirt
      ];
    })

    # CLIENT configuration
    (lib.mkIf (cfg.role == "client" || cfg.role == "both") {
      environment.systemPackages = with pkgs;
        [ ]
        ++ lib.optional cfg.client.enableVirtManager virt-manager
        ++ lib.optional cfg.client.enableVirtViewer virt-viewer
        ++ lib.optionals cfg.client.enableSpice [
          spice-gtk
          spice-protocol
        ]
        ++ cfg.client.extraPackages;

      # For client-only mode, enable libvirt in client mode
      virtualisation.libvirtd.enable = lib.mkIf (cfg.role == "client") true;
    })

    # User management
    (lib.mkIf (cfg.users != []) {
      users.users = lib.mkMerge (
        map (username: {
          ${username}.extraGroups = [ "libvirtd" "kvm" ];
        }) cfg.users
      );
    })
  ]);
}

{
  description = "My NixOS modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... } @ inputs: {
    lib = import ./lib { inherit inputs; };

    homeModules = {
      apps = {
        "3dprinting" = ./modules/home/apps/3dprinting.nix;
        alacritty = ./modules/home/apps/alacritty.nix;
        audio = ./modules/home/apps/audio.nix;
        browser-brave = ./modules/home/apps/browser-brave.nix;
        browser-chromium = ./modules/home/apps/browser-chromium.nix;
        browser-firefox = ./modules/home/apps/browser-firefox.nix;
        images = ./modules/home/apps/images.nix;
        kitty = ./modules/home/apps/kitty.nix;
        kodi = ./modules/home/apps/kodi.nix;
        office = ./modules/home/apps/office.nix;
        password-manager = ./modules/home/apps/password-manager.nix;
        protonvpn = ./modules/home/apps/protonvpn.nix;
        rustdesk = ./modules/home/apps/rustdesk.nix;
        veracrypt = ./modules/home/apps/veracrypt.nix;
        video = ./modules/home/apps/video.nix;
      };

      wm = {
        sway = {
            base = ./modules/home/wm/sway/base.nix;
            notification = ./modules/home/wm/sway/notification.nix;
        };

        gtk-apps = ./modules/home/wm/gtk-apps.nix;
        gtk = ./modules/home/wm/gtk.nix;
        qt-apps = ./modules/home/wm/qt-apps.nix;
        qt = ./modules/home/wm/qt.nix;
        wayland = ./modules/home/wm/wayland.nix;
      };

      dev = ./modules/home/dev.nix;
      sound = ./modules/home/sound.nix;
    };

    nixosModules = {
      core = {
        bootloader = ./modules/nixos/core/bootloader.nix;
        locale = ./modules/nixos/core/locale.nix;
        maintenance = ./modules/nixos/core/maintenance.nix;
        nix = ./modules/nixos/core/nix.nix;
        nixpkgs = ./modules/nixos/core/nixpkgs.nix;
        time = ./modules/nixos/core/time.nix;
      };

      features = {
        desktop = {
          wayland = {
            wm = {
              sway = ./modules/nixos/features/desktop/wayland/wm/sway.nix;
            };
          };

          appimage = ./modules/nixos/features/desktop/appimage.nix;
          thunar = ./modules/nixos/features/desktop/thunar.nix;
          xdg = ./modules/nixos/features/desktop/xdg.nix;
        };

        ntp = {
          chrony = ./modules/nixos/features/ntp/chrony.nix;
          ntpd = ./modules/nixos/features/ntp/ntpd.nix;
        };

        packages = {
          all = ./modules/nixos/features/packages/default.nix;

          compression = ./modules/nixos/features/packages/compression.nix;
          development = ./modules/nixos/features/packages/development.nix;
          editors = ./modules/nixos/features/packages/editors.nix;
          hardware = ./modules/nixos/features/packages/hardware.nix;
          monitoring = ./modules/nixos/features/packages/monitoring.nix;
          networking = ./modules/nixos/features/packages/networking.nix;
          nix-tools = ./modules/nixos/features/packages/nix-tools.nix;
          shell = ./modules/nixos/features/packages/shell.nix;
          system-info = ./modules/nixos/features/packages/system-info.nix;
          text-processing = ./modules/nixos/features/packages/text-processing.nix;
          utilities = ./modules/nixos/features/packages/utilities.nix;
        };

        security = {
          crypto = {
            libressl = ./modules/nixos/features/security/crypto/libressl.nix;
          };

          luks = {
            basic = ./modules/nixos/features/security/luks/basic.nix;
            remote-unlock = ./modules/nixos/features/security/luks/remote-unlock.nix;
          };

          audit = ./modules/nixos/features/security/audit.nix;
          baseline = ./modules/nixos/features/security/baseline.nix;
          gpg = ./modules/nixos/features/security/gpg.nix;
          hardened = ./modules/nixos/features/security/hardened.nix;
          pki-certificates = ./modules/nixos/features/security/pki-certificates.nix;
          secrets = ./modules/nixos/features/security/secrets.nix;
          secureboot = ./modules/nixos/features/security/secureboot.nix;
          sudo-nopasswd = ./modules/nixos/features/security/sudo-nopasswd.nix;
          yubikey = ./modules/nixos/features/security/yubikey.nix;
        };

        system = {
          auto-upgrade = ./modules/nixos/features/system/auto-upgrade.nix;
          cross-compilation = ./modules/nixos/features/system/cross-compilation.nix;
          filesystem = ./modules/nixos/features/system/filesystem.nix;
          ipv6-disable = ./modules/nixos/features/system/ipv6-disable.nix;
          iso-builder = ./modules/nixos/features/system/iso-builder.nix;
        };

        virtualisation = {
          docker = ./modules/nixos/features/virtualisation/docker.nix;
          libvirt = ./modules/nixos/features/virtualisation/libvirt.nix;
          podman = ./modules/nixos/features/virtualisation/podman.nix;
        };

        console = ./modules/nixos/features/console.nix;
        fonts = ./modules/nixos/features/fonts.nix;
        networking = ./modules/nixos/features/networking.nix;
        power-management = ./modules/nixos/features/power-management.nix;
        quietboot = ./modules/nixos/features/quietboot.nix;
        spellcheck = ./modules/nixos/features/spellcheck.nix;
        unfree = ./modules/nixos/features/unfree.nix;
      };

      hardware = {
        bluetooth = ./modules/nixos/hardware/bluetooth.nix;
        framework = ./modules/nixos/hardware/framework.nix;
        sound = ./modules/nixos/hardware/sound.nix;
        ssd = ./modules/nixos/hardware/ssd.nix;
      };

      profiles = {
        base = ./modules/nixos/profiles/base.nix;
        laptop = ./modules/nixos/profiles/laptop.nix;
        server = ./modules/nixos/profiles/server.nix;
        workstation = ./modules/nixos/profiles/workstation.nix;
      };

      services = {
        prometheus = {
          nodeExporter = ./modules/nixos/services/prometheus/node-exporter.nix;
        };
        openssh = {
          client = ./modules/nixos/services/openssh/client.nix;
          server = ./modules/nixos/services/openssh/server.nix;
        };
      };
    };

    overlays.default = import ./overlays { inherit inputs; };
  };
}

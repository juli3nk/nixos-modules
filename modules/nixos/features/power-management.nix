{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.nixos.features.powerManagement;

  # Automatically detect the first available swap
  autoDetectedSwap =
    if (lib.length config.swapDevices) > 0
    then (lib.head config.swapDevices).device
    else null;

  # Calculate swapfile size based on RAM
  calculatedSwapSize =
    if cfg.swapfile.autoSize
    then null  # Will be calculated at runtime
    else cfg.swapfile.size;

  # Determine effective device based on mode
  effectiveSwapDevice =
    if cfg.useSwapfile
    then cfg.swapfile.path
    else if cfg.swapDevice != null
    then cfg.swapDevice
    else autoDetectedSwap;

  # Check if it's a swapfile (not a partition)
  isSwapfile = cfg.useSwapfile || (effectiveSwapDevice != null && lib.hasPrefix "/" effectiveSwapDevice && !lib.hasPrefix "/dev/" effectiveSwapDevice);

  # Script to get system RAM size
  getRamSizeScript = pkgs.writeShellScript "get-ram-size" ''
    # Returns RAM in MB
    awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo
  '';

  # Script to check disk space
  checkDiskSpaceScript = pkgs.writeShellScript "check-disk-space" ''
    SWAP_PATH="$1"
    REQUIRED_SIZE_MB="$2"

    # Get mount point of the file
    MOUNT_POINT=$(df -P "$(dirname "$SWAP_PATH")" 2>/dev/null | tail -1 | awk '{print $6}')

    if [ -z "$MOUNT_POINT" ]; then
      echo "ERROR: Cannot determine mount point for $SWAP_PATH"
      exit 1
    fi

    # Available space in MB
    AVAILABLE_MB=$(df -BM "$MOUNT_POINT" | tail -1 | awk '{print int($4)}' | sed 's/M//')

    echo "Mount point: $MOUNT_POINT"
    echo "Available space: ''${AVAILABLE_MB}MB"
    echo "Required space: ''${REQUIRED_SIZE_MB}MB"

    if [ "$AVAILABLE_MB" -lt "$REQUIRED_SIZE_MB" ]; then
      echo "ERROR: Insufficient disk space!"
      echo "Available: ''${AVAILABLE_MB}MB, Required: ''${REQUIRED_SIZE_MB}MB"
      exit 1
    fi

    echo "OK: Sufficient disk space available"
    exit 0
  '';

  # Script to calculate optimal swapfile size
  calculateSwapSizeScript = pkgs.writeShellScript "calculate-swap-size" ''
    RAM_MB=$(${getRamSizeScript})
    MULTIPLIER="${cfg.swapfile.sizeMultiplier}"
    MIN_SIZE=${toString cfg.swapfile.minimumSize}
    MAX_SIZE=${toString cfg.swapfile.maximumSize}

    echo "Detected RAM: ''${RAM_MB}MB"

    # Calculate size based on multiplier
    case "$MULTIPLIER" in
      "auto")
        # Recommended sizing based on RAM
        if [ "$RAM_MB" -le 2048 ]; then
          SWAP_SIZE=$((RAM_MB * 2))  # RAM <= 2GB: 2x RAM
        elif [ "$RAM_MB" -le 8192 ]; then
          SWAP_SIZE=$RAM_MB           # 2GB < RAM <= 8GB: 1x RAM
        else
          SWAP_SIZE=$((RAM_MB / 2))   # RAM > 8GB: 0.5x RAM
        fi
        ;;
      "equal")
        SWAP_SIZE=$RAM_MB
        ;;
      "double")
        SWAP_SIZE=$((RAM_MB * 2))
        ;;
      "half")
        SWAP_SIZE=$((RAM_MB / 2))
        ;;
      *)
        # Custom multiplier (e.g., "1.5")
        SWAP_SIZE=$(echo "$RAM_MB * $MULTIPLIER" | ${pkgs.bc}/bin/bc | ${pkgs.coreutils}/bin/cut -d. -f1)
        ;;
    esac

    # Apply min/max bounds
    if [ "$SWAP_SIZE" -lt "$MIN_SIZE" ]; then
      SWAP_SIZE=$MIN_SIZE
    fi

    if [ "$MAX_SIZE" -gt 0 ] && [ "$SWAP_SIZE" -gt "$MAX_SIZE" ]; then
      SWAP_SIZE=$MAX_SIZE
    fi

    echo "Calculated swap size: ''${SWAP_SIZE}MB"
    echo "$SWAP_SIZE"
  '';

  # Script to get swapfile offset
  getSwapfileOffsetScript = pkgs.writeShellScript "get-swapfile-offset" ''
    SWAPFILE="$1"

    if [ ! -f "$SWAPFILE" ]; then
      echo "ERROR: $SWAPFILE does not exist"
      exit 1
    fi

    OFFSET=$(${pkgs.e2fsprogs}/bin/filefrag -v "$SWAPFILE" 2>/dev/null | awk '$1=="0:" {print $4}' | sed 's/\.\.$//')

    if [ -z "$OFFSET" ]; then
      echo "ERROR: Cannot calculate offset"
      exit 1
    fi

    echo "$OFFSET"
  '';

  # Script to create and setup swapfile
  setupSwapfileScript = pkgs.writeShellScript "setup-swapfile" ''
    set -e

    SWAPFILE="${cfg.swapfile.path}"

    # Calculate size if auto
    if ${if cfg.swapfile.autoSize then "true" else "false"}; then
      SWAP_SIZE=$(${calculateSwapSizeScript})
    else
      SWAP_SIZE=${toString cfg.swapfile.size}
    fi

    echo "Setting up swapfile at $SWAPFILE with size ''${SWAP_SIZE}MB"

    # Check if enough space is available
    ${checkDiskSpaceScript} "$SWAPFILE" "$SWAP_SIZE" || exit 1

    # Check if swapfile already exists
    if [ -f "$SWAPFILE" ]; then
      CURRENT_SIZE=$(stat -c%s "$SWAPFILE")
      CURRENT_SIZE_MB=$((CURRENT_SIZE / 1024 / 1024))

      if [ "$CURRENT_SIZE_MB" -eq "$SWAP_SIZE" ]; then
        echo "Swapfile already exists with correct size (''${CURRENT_SIZE_MB}MB)"

        # Check if already swap
        if ${pkgs.util-linux}/bin/swapon --show | grep -q "$SWAPFILE"; then
          echo "Swapfile is already active"
          exit 0
        fi
      else
        echo "Swapfile exists but has wrong size (''${CURRENT_SIZE_MB}MB != ''${SWAP_SIZE}MB)"
        echo "Disabling and removing old swapfile..."
        ${pkgs.util-linux}/bin/swapoff "$SWAPFILE" 2>/dev/null || true
        rm -f "$SWAPFILE"
      fi
    fi

    # Create swapfile
    echo "Creating swapfile..."
    ${pkgs.coreutils}/bin/dd if=/dev/zero of="$SWAPFILE" bs=1M count="$SWAP_SIZE" status=progress
    ${pkgs.coreutils}/bin/chmod 600 "$SWAPFILE"

    # Format as swap
    echo "Formatting swapfile..."
    ${pkgs.util-linux}/bin/mkswap "$SWAPFILE"

    # Enable swap
    echo "Enabling swapfile..."
    ${pkgs.util-linux}/bin/swapon "$SWAPFILE"

    # Calculate and display offset for hibernation
    echo ""
    echo "=== Hibernation Setup ==="
    OFFSET=$(${getSwapfileOffsetScript} "$SWAPFILE")
    echo "Resume offset: $OFFSET"
    echo ""
    echo "Add to your configuration.nix:"
    echo "  modules.powerManagement.swapfile.resumeOffset = $OFFSET;"
    echo ""
  '';

in
{
  options.myModules.nixos.features.powerManagement = {
    enable = lib.mkEnableOption "Advanced power management configuration";

    # === Swap Configuration ===

    swapDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/disk/by-uuid/29c20e93-1ccb-4868-9af1-d043f38e4447";
      description = ''
        UUID or path of swap partition for hibernation.
        If null, automatically uses the first swap found in swapDevices.
        Ignored if useSwapfile = true.
      '';
    };

    useSwapfile = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use a swapfile instead of a swap partition";
    };

    swapfile = {
      path = lib.mkOption {
        type = lib.types.str;
        default = "/swapfile";
        example = "/var/swapfile";
        description = "Path to the swapfile";
      };

      size = lib.mkOption {
        type = lib.types.int;
        default = 16384;
        example = 32768;
        description = "Swapfile size in MB (must be >= RAM for hibernation). Ignored if autoSize = true.";
      };

      autoSize = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Automatically calculate swapfile size based on RAM.
          Recommended for most use cases.
        '';
      };

      sizeMultiplier = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        example = "1.5";
        description = ''
          How to calculate swapfile size relative to RAM:
          - "auto": Smart sizing (2x for <=2GB, 1x for <=8GB, 0.5x for >8GB)
          - "equal" or "1": Same as RAM
          - "double" or "2": Double RAM
          - "half" or "0.5": Half RAM
          - Any number: Custom multiplier (e.g., "1.5" for 1.5x RAM)
        '';
      };

      minimumSize = lib.mkOption {
        type = lib.types.int;
        default = 8192;
        description = "Minimum swapfile size in MB (safety lower bound)";
      };

      maximumSize = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Maximum swapfile size in MB (0 = no limit)";
      };

      resumeOffset = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 34816;
        description = ''
          Resume offset for the swapfile (required for hibernation).
          Get it with: sudo filefrag -v /swapfile | awk '$1=="0:" {print $4}' | sed 's/\.\.//'
          If null, you must configure it manually in boot.kernelParams or run setup-swapfile
        '';
      };

      autoCalculateOffset = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Try to automatically calculate resume_offset at boot.
          EXPERIMENTAL: may not work on all filesystems.
        '';
      };
    };

    # === Hibernation Settings ===

    hibernateDelay = lib.mkOption {
      type = lib.types.str;
      default = "2h";
      example = "90min";
      description = "Delay before hibernating after suspend (systemd time format)";
    };

    # === Idle Settings ===

    idleTimeout = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      example = "15min";
      description = "Idle time before suspend-then-hibernate (systemd time format)";
    };

    enableOnPowerButton = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable suspend-then-hibernate on power button press";
    };

    # === Debug ===

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show debug information in warnings";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # === Assertions and Warnings ===
    {
      assertions = [
        {
          assertion = effectiveSwapDevice != null;
          message = ''
            No swap configured!
            Either:
            - Set modules.powerManagement.swapDevice
            - Enable modules.powerManagement.useSwapfile
            - Configure swapDevices in hardware-configuration.nix
          '';
        }
        {
          assertion = !cfg.useSwapfile || cfg.swapfile.resumeOffset != null || cfg.swapfile.autoCalculateOffset;
          message = ''
            Swapfile hibernation requires resume_offset!
            Either:
            - Set modules.powerManagement.swapfile.resumeOffset manually
            - Enable modules.powerManagement.swapfile.autoCalculateOffset (experimental)
            - Run: sudo setup-swapfile (after rebuild)
          '';
        }
        {
          assertion = !cfg.swapfile.autoSize || cfg.swapfile.sizeMultiplier != "";
          message = "sizeMultiplier cannot be empty when autoSize is enabled";
        }
      ];

      warnings =
        lib.optional (cfg.useSwapfile && cfg.swapfile.autoSize) ''
          Swapfile auto-sizing enabled. Size will be calculated based on RAM at boot time.
          Multiplier: ${cfg.swapfile.sizeMultiplier}
          Min: ${toString cfg.swapfile.minimumSize}MB, Max: ${if cfg.swapfile.maximumSize > 0 then "${toString cfg.swapfile.maximumSize}MB" else "unlimited"}
        ''
        ++
        lib.optional cfg.debug ''
          PowerManagement Debug Info:
          - Swap mode: ${if cfg.useSwapfile then "swapfile" else "partition"}
          - Effective swap device: ${toString effectiveSwapDevice}
          - Auto-detected swap: ${toString autoDetectedSwap}
          - Resume device: ${config.boot.resumeDevice}
          ${lib.optionalString cfg.useSwapfile ''
          - Swapfile path: ${cfg.swapfile.path}
          - Swapfile auto-size: ${toString cfg.swapfile.autoSize}
          - Swapfile size: ${if cfg.swapfile.autoSize then "auto (${cfg.swapfile.sizeMultiplier})" else "${toString cfg.swapfile.size}MB"}
          - Resume offset: ${toString cfg.swapfile.resumeOffset}
          ''}
        '';
    }

    # === Swap Configuration ===
    (lib.mkIf (!cfg.useSwapfile && cfg.swapDevice != null) {
      # Partition swap mode
      swapDevices = lib.mkForce [{
        device = cfg.swapDevice;
      }];

      boot.resumeDevice = cfg.swapDevice;
    })

    (lib.mkIf cfg.useSwapfile {
      # Swapfile mode
      swapDevices = lib.mkForce [{
        device = cfg.swapfile.path;
        size = if cfg.swapfile.autoSize then 0 else cfg.swapfile.size;  # 0 = managed manually
      }];

      boot.resumeDevice = cfg.swapfile.path;

      # Add resume_offset to kernel parameters

      # Systemd service to setup swapfile
      systemd.services.setup-swapfile = {
        description = "Setup swapfile for hibernation";
        wantedBy = [ "multi-user.target" ];
        before = [ "swap.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${setupSwapfileScript}";
          RemainAfterExit = true;
        };
      };

      # Auto-calculate offset at boot (experimental)
      boot.kernelParams = lib.mkIf (cfg.swapfile.autoCalculateOffset && cfg.swapfile.resumeOffset == null) [
        "resume_offset=$(${getSwapfileOffsetScript} ${cfg.swapfile.path})"
      ];
    })

    # === Power Management ===
    {
      boot.kernelParams = lib.mkMerge [
        [ "mem_sleep_default=deep" ]

        (lib.mkIf (cfg.swapfile.resumeOffset != null) [
          "resume_offset=${toString cfg.swapfile.resumeOffset}"
        ])
      ];

      services.logind.extraConfig = ''
        HandleLidSwitch=suspend-then-hibernate
        HandleLidSwitchExternalPower=suspend
        IdleAction=suspend-then-hibernate
        IdleActionSec=${cfg.idleTimeout}
        ${lib.optionalString cfg.enableOnPowerButton ''
          HandlePowerKey=suspend-then-hibernate
          HandlePowerKeyLongPress=poweroff
        ''}
      '';

      systemd.sleep.extraConfig = ''
        HibernateDelaySec=${cfg.hibernateDelay}
        HibernateMode=platform
        SuspendState=mem
      '';

      # Filesystem optimizations
      fileSystems."/".options = [
        "noatime"
        "nodiratime"
        "discard"
      ];

      powerManagement = {
        enable = true;
        powertop.enable = true;
      };
    }

    # === Helper Tools ===
    {
      environment.systemPackages = [
        # Swapfile management tool
        (pkgs.writeShellScriptBin "setup-swapfile" ''
          if [ "$EUID" -ne 0 ]; then
            echo "Please run as root (sudo setup-swapfile)"
            exit 1
          fi
          ${setupSwapfileScript}
        '')

        # Check disk space tool
        (pkgs.writeShellScriptBin "check-swap-space" ''
          SWAP_PATH="${cfg.swapfile.path}"

          if ${if cfg.swapfile.autoSize then "true" else "false"}; then
            REQUIRED_SIZE=$(${calculateSwapSizeScript})
          else
            REQUIRED_SIZE=${toString cfg.swapfile.size}
          fi

          ${checkDiskSpaceScript} "$SWAP_PATH" "$REQUIRED_SIZE"
        '')

        # Get offset tool
        (pkgs.writeShellScriptBin "get-swapfile-offset" ''
          SWAPFILE="${cfg.swapfile.path}"

          if [ ! -f "$SWAPFILE" ]; then
            echo "Swapfile $SWAPFILE does not exist yet"
            echo "Run: sudo setup-swapfile"
            exit 1
          fi

          OFFSET=$(${getSwapfileOffsetScript} "$SWAPFILE")

          echo "Resume offset for $SWAPFILE: $OFFSET"
          echo ""
          echo "Add to your configuration.nix:"
          echo "  modules.powerManagement.swapfile.resumeOffset = $OFFSET;"
        '')

        # Show RAM and calculated swap size
        (pkgs.writeShellScriptBin "show-swap-info" ''
          RAM_MB=$(${getRamSizeScript})
          echo "System RAM: ''${RAM_MB}MB"
          echo ""

          if ${if cfg.swapfile.autoSize then "true" else "false"}; then
            SWAP_SIZE=$(${calculateSwapSizeScript})
            echo "Calculated swap size: ''${SWAP_SIZE}MB"
          else
            echo "Configured swap size: ${toString cfg.swapfile.size}MB"
          fi

          echo ""
          echo "Current swap status:"
          swapon --show
        '')
      ];
    }
  ]);
}

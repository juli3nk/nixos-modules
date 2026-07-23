# Laptop profile
{ pkgs, ... }:

{
  imports = [
    ./base.nix

    ../hardware/ssd.nix
    ../hardware/bluetooth.nix
    ../hardware/sound.nix

    ../features/ntp/chrony.nix
    ../features/security/baseline.nix
    ../features/system/filesystem-extra.nix
    ../features/fonts.nix
    ../features/networking.nix
    ../features/spellcheck.nix
    ../features/power-management.nix
  ];

  # ========================================
  # Firmwares
  # ========================================
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # ========================================
  # Laptop-specific hardware
  # ========================================

  # SSD
  myModules.nixos.hardware.ssd.enable = true;

  # ========================================
  # System stability
  # ========================================

  # systemd OOM Killer (prevents freezes when RAM is full)
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  # Zram (RAM compression, saves ~30% RAM)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;  # Uses 50% RAM for zram
  };

  # ========================================
  # Laptop power management
  # ========================================

  # Suspend-then-hibernate
  myModules.nixos.features.powerManagement = {
    enable = true;
    idleTimeout = "15min";
    hibernateDelay = "2h";
  };

  # ========================================
  # Touchpad
  # ========================================
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      tappingDragLock = true;
      disableWhileTyping = true;
      clickMethod = "clickfinger";  # 2 fingers = right click, 3 fingers = middle click
      accelSpeed = "0.3";
      accelProfile = "adaptive";
      middleEmulation = false;      # Disables middle click emulation (annoying)
      scrollMethod = "twofinger";
    };
  };

  # ========================================
  # Screen brightness
  # ========================================

  # Illum (auto-adjustment daemon)
  services.illum.enable = true;

  # ========================================
  # Laptop packages
  # ========================================
  environment.systemPackages = with pkgs; [
    acpi             # ACPI info (battery, temperature)
    brightnessctl
    nvme-cli         # NVMe SSD health
    v4l-utils        # webcam: v4l2-ctl, qv4l2
  ];
}

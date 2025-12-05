{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    aide
    lynis
  ];

  services = {
    clamav = {
      daemon.enable = false;
      updater.enable = true;
    };
  };
}

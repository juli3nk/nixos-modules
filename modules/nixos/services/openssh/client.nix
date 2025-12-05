{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.openssh ];
}

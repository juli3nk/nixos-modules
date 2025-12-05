# Nixpkgs configuration
{ ... }:

{
  nixpkgs.config = {
    # Strict policy by default
    allowUnfree = false;
    allowUnsupportedSystem = false;

    # Security: no insecure packages
    permittedInsecurePackages = [];
  };
}

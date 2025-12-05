{ lib, ... }:

{
  security.sudo.wheelNeedsPassword = lib.mkForce false;
  
  # Visible warning
  warnings = [
    ''
      ⚠️  Passwordless sudo enabled!
      All users in the 'wheel' group have immediate root access.
      Do not use on sensitive machines.
    ''
  ];
}

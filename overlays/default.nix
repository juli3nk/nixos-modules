{ inputs }:

[
  # Overlay unstable
  (import ./unstable.nix { inherit inputs; })

  # Packages custom
  # (import ./custom-pkgs.nix)

  # Modifications
  # (import ./modifications.nix)
]

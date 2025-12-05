{ inputs }:

{
  hostname,
  username ? "nixos",
  system ? "x86_64-linux",
  hasHomeManager ? true,
  hasSops ? false,
  hostPath ? null,
  extraModules ? [],
  overlays ? [],
  defaultOverlays ? true,
  specialArgs ? {},
}:

let
  inherit (inputs) nixpkgs nixpkgs-unstable home-manager sops-nix;
  inherit (nixpkgs) lib;

  pkgs-unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  homeFile = if hostPath != null then hostPath + "/home.nix" else null;
  hasHomeFile = homeFile != null && builtins.pathExists homeFile;

  sharedSpecialArgs = {
    inherit inputs pkgs-unstable hostname username;
    nixos-modules = inputs.self;
  } // specialArgs;
in
  nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = sharedSpecialArgs;
    
    modules = [
      {
        nix.registry.nixpkgs.flake = nixpkgs;
        environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
        nix.nixPath = ["/etc/nix/inputs"];

        networking.hostName = hostname;

        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = if defaultOverlays 
          then overlays 
          else [];
      }
    ]

    # Import host only if provided
    ++ lib.optionals (hostPath != null) [ hostPath ]

    # Optionnal: Home Manager
    ++ lib.optionals (hasHomeManager && hasHomeFile) [
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;

          extraSpecialArgs = sharedSpecialArgs;

          users.${username} = lib.mkMerge [
            # Default configuration (without stateVersion)
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
              programs.home-manager.enable = true;
            }
            
            (import homeFile)
          ];
        };
      }
    ]
  
    # Optionnal: sops-nix
    ++ lib.optional hasSops [
      inputs.sops-nix.nixosModules.sops
    ]

    # Additionnals modules (hardware, etc.)
    ++ extraModules;
  }

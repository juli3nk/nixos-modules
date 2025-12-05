{ inputs }:

{
  # Main function to create a host
  mkHost = import ./mkHost.nix { inherit inputs; };
  
  # Helper to import multiple modules easily
  importModules = modulesList: 
    map (m: inputs.self.nixosModules.${m}) modulesList;
}

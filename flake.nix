{
  inputs.nixos.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.home-manager = {
    url = "github:rycee/home-manager/master";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  outputs = { self, nixos, nixpkgs, ... }@inputs: {

    homeManagerConfigurations = {
      cstrahan = inputs.home-manager.lib.homeManagerConfiguration {
        configuration = ./home.nix;
        system = "x86_64-linux";
        homeDirectory = "/home/cstrahan";
        username = "cstrahan";
      };
    };

    nixosConfigurations.cstrahan-nixos = nixos.lib.nixosSystem {
      specialArgs = {
        meta = { hostname = "cstrahan-nixos"; };
      }; 
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # pin NIX_PATH and flake registry
        {
          nix.nixPath = [
            "nixpkgs=${nixpkgs}"
          ];
          nix.registry.nixpkgs.flake = nixpkgs;
          #system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        }
      ];
    };

  };
}

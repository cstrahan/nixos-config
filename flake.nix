{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.home-manager = {
    url = "github:rycee/home-manager/master";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  outputs = { self, ... }@inputs: {

    homeManagerConfigurations = {
      cstrahan = inputs.home-manager.lib.homeManagerConfiguration {
        configuration = ./home.nix;
        system = "x86_64-linux";
        homeDirectory = "/home/cstrahan";
        username = "cstrahan";
      };
    };

  };
}

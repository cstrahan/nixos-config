# About

My personal NixOS configuration.

# Example

```
echo '{ hostname = "<HOSTNAME>"; }' > meta.nix

nixos-rebuild build -I nixpkgs=$HOME/src/nixpkgs -I nixos-config=$PWD/configuration.nix
```

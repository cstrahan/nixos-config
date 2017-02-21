# About

My personal NixOS configuration.

# Example

```
echo "{ hostname = \"$(hostname)\"; productName = \"$(cat /sys/class/dmi/id/product_name)\"; }" > meta.nix

nixos-rebuild build -I nixpkgs=$HOME/src/nixpkgs -I nixos-config=$PWD/configuration.nix
```

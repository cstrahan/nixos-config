# About

My personal NixOS configuration.

# Example

```
echo "{ hostname = \"$(hostname)\"; productName = \"$(cat /sys/class/dmi/id/product_name)\"; }" > meta.nix

nixos-rebuild build -I nixpkgs=$HOME/src/nixpkgs -I nixos-config=$PWD/configuration.nix
```

# Home Management

```
# build
$ nix --experimental-features 'flakes nix-command' build .#homeManagerConfigurations.cstrahan.activationPackage

# dry-run activate
$ DRY_RUN=1 ./result/activate

# activate
$ ./result/activate
```



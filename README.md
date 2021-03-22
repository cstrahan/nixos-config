# About

My personal NixOS configuration.

# Example

To build:

```
nixos-rebuild build --flake '.#'
```

To switch:

```
sudo nixos-rebuild switch --flake '.#'
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



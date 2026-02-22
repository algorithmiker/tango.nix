NixOS module to run a Tango Controls device server.
Will be upstreamed eventually.

## Usage

```nix
# flake.nix
inputs = {
  tango-nix = {
    url = "github:algorithmiker/tango.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

# configuration.nix
imports = [tango-nix.nixosModules.tango-controls];
services.tango-controls.enable = true;
```

{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = (nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed);
    in
    {
      nixosModules.tango-controls = ./tango.module.nix;

      nixosConfigurations."test" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            imports = [ ./tango.module.nix ];
            services.tango-controls = {
              enable = true;
              autoStart = true;
            };
            users.users.root1 = {
              password = "root";
              enable = true;
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };
          }
        ];
      };
      checks = forAllSystems (system: {
        test-db-creation = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "test-db-creation";
          nodes.machine =
            { config, pkgs, ... }:
            {
              imports = [ ./tango.module.nix ];
              services.tango-controls = {
                enable = true;
                autoStart = true;
              };
            };
          testScript = ''
            machine.wait_for_unit("tango.service")
          '';
        };
      });
    };
}

let
  nix = import ./nix;
  nixpkgs = nix.nixpkgs;
  nixus = import nix.nixus;

  overlays = [ (import ./overlays.nix) ];

  nixpkgsRev = builtins.substring 0 8 nixpkgs.rev;

  mkConfigure = { name, hostname, hostConfiguration }:
    nixus ({ ... }: {
      defaults = { ... }: {
        inherit nixpkgs;
        configuration = { lib, ... }: {
          # Extract the revision number from nixpkgs
          system.nixos.revision = nixpkgs.rev;
          system.nixos.versionSuffix = ".${nixpkgsRev}";
          system.nixos.tags = [ "with-nixus" ];

          # Allow installing non-free packages by default
          nixpkgs.config.allowUnfree = true;
        };
      };

      nodes.${name} =
        { ... }:
        {
          host = "root@localhost";
          configuration = {
            imports = [ ./configuration.nix hostConfiguration ];

            my = {
              inherit hostname;
              username = "nicolas";
              userHomeConfiguration = ./user/home.nix;
            };

            # Mandatory for the deployment with NixOps/Nixus
            services.openssh = {
              enable = true;
              permitRootLogin = "without-password";
              passwordAuthentication = false;
              listenAddresses = [ { addr = "localhost"; port = 22; } ];
            };
            # users.mutableUsers = false;
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtEC0M+d90ew2Otfn/B/gDOJhv+uByid44uAtO4ZV9K"
            ];
          };
        };
    });
in
{
  merovingian = mkConfigure {
    name = "merovingian";
    hostname = "merovingian";
    hostConfiguration = ./nixos/host/merovingian.nix;
  };
}

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
  };
  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        ./nix/ngrok-outputs.nix
      ];
      flake = {
        nixosConfigurations.jenkins-nix-ci = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            ./nix/configuration.nix
            ./nix/ngrok.nix
          ];
        };
        deploy.nodes.jenkins-nix-ci =
          let
            ngrokPort = 19112;
          in
          {
            hostname = "0.tcp.in.ngrok.io";
            sshOpts = [ "-p" (builtins.toString ngrokPort) ];
            sshUser = "admin";
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.jenkins-nix-ci;
            };
          };
      };
      perSystem = { self', inputs', system, lib, config, pkgs, ... }: {
        # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
            inputs'.deploy-rs.packages.default
            inputs'.agenix.packages.agenix
          ];
        };

        apps = {
          # Deploy
          default = {
            type = "app";
            program = "${inputs'.deploy-rs.packages.deploy-rs}/bin/deploy";
          };
        };
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}

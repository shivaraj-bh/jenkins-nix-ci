{ lib, pkgs, config, secrets, ... }:

let
  types = lib.types;
  casc = config.cascLib;
in
{
  options.features.cachix = {
    enable = lib.mkEnableOption "cachix";

    casc.credentials = lib.mkOption {
      type = types.listOf types.attrs;
      default = [
        {
          string = {
            id = "cachix-auth-token";
            description = casc.readFile secrets."jenkins-nix-ci/cachix-auth-token/description".path;
            secret = casc.readFile secrets."jenkins-nix-ci/cachix-auth-token/secret".path;
          };
        }
      ];
    };

    sharedLibrary.vars = [
      ../../../../groovy-library/cachixPush.groovy
    ];

    node.packages = lib.mkOption {
      type = types.listOf types.package;
      default = [
        pkgs.cachix
        (pkgs.callPackage ../../../../groovy-library/vars/cachixPush.nix { inherit pkgs; })
      ];
    };
  };
}

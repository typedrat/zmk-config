{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zmk-nix,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);

    # Define keyboard configurations
    keyboards = {
      void40 = {
        board = "nice_nano_v2";
        shield = "void40";
        zephyrDepsHash = "sha256-79/rYCtUDlC0K4ARO9MSEaCcI1RQSsv7MCeayVZSwtQ=";
        description = "VOID40 custom hand-wired keyboard";
        split = false;
        enableZmkStudio = true;
      };
    };

    # Helper function to build a keyboard package
    buildKeyboard = system: name: config: let
      buildFunction =
        if config.split
        then zmk-nix.legacyPackages.${system}.buildSplitKeyboard
        else zmk-nix.legacyPackages.${system}.buildKeyboard;

      firmware =
        (buildFunction {
          name = "${name}-firmware";

          src = nixpkgs.lib.sourceFilesBySuffices self [
            ".board"
            ".cmake"
            ".conf"
            ".defconfig"
            ".dts"
            ".dtsi"
            ".json"
            ".keymap"
            ".overlay"
            ".shield"
            ".yml"
            "_defconfig"
          ];

          board = config.board;
          shield = config.shield;
          zephyrDepsHash = config.zephyrDepsHash;
          enableZmkStudio = config.enableZmkStudio;
          snippets = ["zmk-usb-logging"];

          meta = {
            description = config.description;
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        }).overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [nixpkgs.legacyPackages.${system}.dtc];
        });

      flash = zmk-nix.packages.${system}.flash.override {inherit firmware;};
      update = zmk-nix.packages.${system}.update;
    in
      # Return firmware as the main derivation, but add sub-attributes
      firmware
      // {
        inherit firmware flash update;
      };
  in {
    packages = forAllSystems (
      system:
        nixpkgs.lib.mapAttrs (name: config: buildKeyboard system name config) keyboards
    );

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}

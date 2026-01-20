{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    mission-control.url = "github:Platonic-Systems/mission-control";
  };
  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-root.flakeModule
        inputs.mission-control.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem =
        { pkgs, config, ... }: let
          app = pkgs.writeShellApplication {
            name = "demo";
            runtimeInputs = with pkgs; [
              omnix
              vhs
              eza
              fontconfig
              nerd-fonts.jetbrains-mono
            ];
            text = ''
              export XDG_DATA_DIRS="${pkgs.nerd-fonts.jetbrains-mono}/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
              vhs ./demo.tape
              rm -rf ./nixconfig
            '';
          };
        in
        {
          apps.default = {
            program = "${app}/bin/demo";
          };
          devShells.default = pkgs.mkShell {
            inputsFrom = [
              config.mission-control.devShell
            ];
            nativeBuildInputs = with pkgs; [
              nix
              omnix
              vhs
              eza
              fontconfig
              nerd-fonts.jetbrains-mono
            ];
          };
          mission-control = {
            wrapperName = "demo";
            scripts = {
              demo = {
                description = "Do all the stuffs";
                exec = ''
                  demo setup
                  demo record
                '';
              };
              record = {
                description = "Record the demo";
                exec = ''
                  vhs ./demo.tape
                  rm -rf ./nixconfig
                '';
              };
              setup = {
                description = "Setup the environemt";
                exec = ''
                  nix flake prefetch github:juspay/nixos-unified-template
                  nix build .#omnix --no-link
                  nix build .#vhs --no-link
                  nix build .#eza --no-link
                  nix build .#nerd-fonts.jetbrains-mono --no-link
                '';
              };
              restore = {
                description = "Clean & Restore the environment";
                exec = ''
                  rm -rf ./nixconfig
                  git restore out.*
                '';
              };
            };
          };
        };
    };
}

{
  description = "Flake for building qmk firmware";

  inputs = {
    qmk-firmware = {
      type = "git";
      url = "https://github.com/zsa/qmk_firmware.git";
      submodules = true;
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      qmk-firmware,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        ini = pkgs.formats.ini { };
        keyboard = "voyager";
        keymap = "default";
        buildDir = "./build";
        configFile = ini.generate "qmk.ini" {
          user = {
            inherit keyboard keymap;
            qmk_home = "${qmk-firmware}";
          };
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "keymap";
          src = ./.;
          phases = [ "buildPhase" ];
          buildInputs = [ pkgs.qmk ];
          buildPhase = ''
            qmk --config-file ${configFile} compile -e BUILD_DIR=$out
          '';
        };

        devShell = pkgs.mkShell {
          buildInputs = [ pkgs.qmk ];
          shellHook = ''
            compile() {
            	qmk --config-file ${configFile} compile -e BUILD_DIR=${buildDir}
            }
            flash() {
            	qmk --config-file ${configFile} flash -e BUILD_DIR=${buildDir} --config-file ${configFile}
            }
          '';
        };
      }
    );
}

{ runCommand, requireFile, unzip }:

let
  name = "pragmatapro-${version}";
  version = "0.820";
in

runCommand name
  rec {
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "07yxp0h63li84qi0hkqr0dlprb4gs5g2b3cbh4s15f0pyfvbgb93";

    src = requireFile rec {
      name = "PragmataPro${version}.zip";
      url = "file://path/to/${name}";
      sha256 = "0dg7h80jaf58nzjbg2kipb3j3w6fz8z5cyi4fd6sx9qlkvq8nckr";
    };

    buildInputs = [ unzip ];
  } ''
    unzip $src

    install_path=$out/share/fonts/truetype/pragmatapro
    mkdir -p $install_path

    find -name "PragmataPro*.ttf" -exec mv {} $install_path \;
  ''

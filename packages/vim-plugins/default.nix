{ stdenv, lib, pkgs, callPackage
, fetchurl, fetchzip, fetchgit, fetchFromGitHub
, cmake
, vim, ruby, python, python3, perl, llvmPackages_7
, which
, darwin
, ycmd
}@args:
let sourcesJson = builtins.fromJSON (builtins.readFile ./sources.json);
    sources = lib.foldl' (acc: x: acc // {
      "${x.name}" = fetchFromGitHub { inherit (x) owner repo rev sha256; };
    }) { } sourcesJson;
    vimHelpTagsDef = ''
      vimHelpTags(){
        if [ -d "$1/doc" ]; then
          echo "generating helptags"
          ${vim}/bin/vim -n -u NONE -i NONE -n -e -s -c "helptags $1/doc" +quit! ||
            echo "WARNING: could not generate helpdocs for $name"
        else
          echo "skipping vim helptags: no doc folder found at $1/doc"
        fi
      }
    '';
    mkVimPlugin = name: src: stdenv.mkDerivation {
      inherit name src;
      preConfigure = ''
        if [[ -f Makefile ]]; then
          rm Makefile
        fi
      '';
      installPhase = ''
        runHook preInstall

        mkdir -p $out/vim-plugins
        target=$out/vim-plugins/$name
        cp -r . $target
        ${vimHelpTagsDef}
        vimHelpTags $target

        runHook postInstall
      '';
    };
    languageclient-bin = fetchurl {
        url = https://github.com/autozimu/LanguageClient-neovim/releases/download/0.1.106/languageclient-0.1.106-x86_64-unknown-linux-musl;
        sha256 = "1qya0z6sgwakivafm2zhm3a2ndv5ds8k3qgpdhcpa2nmndhxwgpw";
    };
    plugins = lib.mapAttrs mkVimPlugin sources // {
      languageclient = stdenv.mkDerivation rec {
        name = "LanguageClient-neovim-${version}";
        version = "0.1.106";
        src = fetchFromGitHub {
          owner = "autozimu";
          repo = "LanguageClient-neovim";
          rev = version;
          sha256 = "06hbp56c0b6y7jjvgf23d2gvvxhqrz53jgczfaqm6asplnn7c1dh";
        };
        buildPhase = "true";
        configurePhase = "true";
        installPhase = ''
          runHook preInstall

          target=$out/vim-plugins/$name
          mkdir -p $target

          mkdir -p $target/bin
          cp -v ${languageclient-bin} $target/bin/languageclient
          chmod +x $target/bin/languageclient

          cp -va autoload $target
          cp -va doc      $target
          cp -va plugin   $target
          cp -va rplugin  $target

          ${vimHelpTagsDef}
          vimHelpTags $target

          runHook postInstall
        '';
        meta = with lib; {
          description = "Language Server Protocol (LSP) support for vim and neovim";
          homepage    = https://github.com/autozimu/LanguageClient-neovim;
          license     = licenses.mit;
          platforms   = platforms.linux;
        };
      };
      youcompleteme = stdenv.mkDerivation {
        name = "youcompleteme";
        src = fetchgit {
          url = "https://github.com/Valloric/YouCompleteMe.git";
          rev = "e252f6512f1f4a9a515dfc42401baf30a5fe72c8";
          sha256 = "0f0jrap8ivrywkzc7rwy27p6ssa5kll26df251ipsg1frmc7fmjm";
        };
        postPatch = ''
          substituteInPlace plugin/youcompleteme.vim --replace \
            "'ycm_path_to_python_interpreter', '''" \
            "'ycm_path_to_python_interpreter', '${python3}/bin/python3'"
        '';
        configurePhase = "true";
        buildPhase = ''
          rm -r third_party/ycmd
          ln -s ${ycmd}/lib/ycmd third_party
        '';
        installPhase = ''
          mkdir -p $out/vim-plugins
          target=$out/vim-plugins/$name
          cp -a ./ $target
          ${vimHelpTagsDef}
          vimHelpTags $target
        '';
        meta = with lib; {
          description = "Fastest non utf-8 aware word and C completion engine for Vim";
          homepage    = http://github.com/Valloric/YouCompleteMe;
          license     = licenses.gpl3;
          platforms   = platforms.unix;
        };
      };
      vimproc = stdenv.mkDerivation {
        name = "vimproc";
        meta = with lib; {
          description = "An asynchronous execution library for Vim";
          homepage    = https://github.com/Shougo/vimproc.vim;
          license     = licenses.gpl3;
          maintainers = with maintainers; [ cstrahan ];
          platforms   = platforms.unix;
        };
        src = sources.vimproc;
        buildInputs = [ which ];
        buildPhase = if stdenv.isLinux then ''
          make -f make_unix.mak
        '' else ''
          make -f make_mac.mak
        '';
        installPhase = ''
          mkdir -p $out/vim-plugins
          target=$out/vim-plugins/$name
          cp -a ./ $target
          ${vimHelpTagsDef}
          vimHelpTags $target
        '';
      };
      command-t = stdenv.mkDerivation {
        name = "command-t";
        src = sources.command-t;
        buildInputs = [ perl ruby ] ++ lib.optional (stdenv.isDarwin) darwin.libobjc;
        buildPhase = ''
          pushd ruby/command-t/ext/command-t
          ruby extconf.rb
          make
          popd
        '';
        installPhase = ''
          mkdir -p $out/vim-plugins
          target=$out/vim-plugins/$name
          cp -a ./ $target
          ${vimHelpTagsDef}
          vimHelpTags $target
        '';
      };
    };
in plugins

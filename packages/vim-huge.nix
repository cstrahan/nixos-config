{ stdenv, glib, gtk2, ncurses, cscope, python2Full, ruby, luajit, perl, tcl
, xorg, gettext, pkgconfig, fetchFromGitHub }:

with xorg;
stdenv.mkDerivation rec {
  name = "vim-${version}";

  version = "8.0.1655";

  dontStrip = 1;

  hardeningDisable = [ "fortify" ];

  src = fetchFromGitHub {
    owner = "vim";
    repo = "vim";
    rev = "v${version}";
    sha256 = "1c6raqjaxgsjazn4l7wqg2cscd5i4bz9m2g2xhn9ba1injs7mps1";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ pkgconfig gettext ];

  buildInputs = [
    glib
    libX11 libXext libSM libXpm libXt libXaw libXau libXmu libICE
    gtk2 ncurses
    cscope
    python2Full ruby luajit perl tcl
  ];

  postPatch =
    # Use man from $PATH; escape sequences are still problematic.
    ''
      substituteInPlace runtime/ftplugin/man.vim \
        --replace "/usr/bin/man " "man "
    '';

  configureFlags = [
      "--enable-cscope"
      "--enable-fail-if-missing"
      "--with-features=huge"
      "--enable-gui=none"
      "--enable-multibyte"
      "--enable-nls"
      "--enable-luainterp=yes"
      "--enable-pythoninterp=yes"
      "--enable-perlinterp=yes"
      "--enable-rubyinterp=yes"
      "--enable-tclinterp=yes"
      "--enable-xim=yes"
      "--with-luajit"
      "--with-lua-prefix=${luajit}"
      "--with-python-config-dir=${python2Full}/lib"
      "--with-ruby-command=${ruby}/bin/ruby"
      "--with-tclsh=${tcl}/bin/tclsh"
      "--with-tlib=ncurses"
      "--with-compiledby=Nix"
  ];

  meta = with stdenv.lib; {
    description = "The most popular clone of the VI editor";
    homepage    = http://www.vim.org;
    maintainers = with maintainers; [ cstrahan ];
    platforms   = platforms.unix;
  };
}

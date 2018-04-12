#let stdenv = [ stdenv.cc stdenv.cc.binutils ] ++ stdenv.initialPath; in

pkgs: with pkgs; [
  # man pages
  man-pages

  # Graphics debugging
  glxinfo
  vdpauinfo # provides vdpauinfo
  libva     # provides vainfo
  xorg.xdriinfo

  google-chrome
  #chromium
  firefoxWrapper
  torbrowser
  idea.idea-community
  #idea.idea-ultimate

  dropbox
  sublime3
  #kde4.kcachegrind
  deluge

  # messaging
  zoom-us
  hipchat
  irssi
  weechat

  # media
  spotify
  mpv
  libreoffice
  abiword
  gimp
  inkscape
  evince
  zathura
  cmus
  sxiv
  exiv2
  #imagemagick

  wineStable
  winetricks

  # X11 stuff
  termite
  rxvt_unicode_with-plugins
  anki
  taffybar
  dmenu2
  xautolock
  xss-lock
  xsel
  xclip
  xlsfonts
  dunst
  stalonetray
  scrot
  haskellPackages.xmobar
  texstudio
  wmctrl
  compton
  xorg.xev
  xorg.xprop
  sxhkd
  rofi
  arandr
  desktop_file_utils
  shared_mime_info
  #devilspie2
  # https://github.com/AndyCrowd/list-desktop-files # TODO

  # CLI tools
  ranger
  #pkg.static-ldd
  #git-series
  xsv
  mtr
  jnettop
  bmon
  iftop
  #mitmproxy # tornado requirement doesn't match
  reptyr
  vmtouch # control system cache
  file
  ncurses.dev # infocmp/tic/etc
  python2Packages.docker_compose
  sshpass
  iw
  mosh
  nssTools
  openssl
  urlview
  lynx
  pass
  notmuch
  neomutt
  msmtp
  isync
  gnupg
  pinentry
  lsof
  usbutils
  xidel
  mkpasswd
  glib # e.g. `gdbus`
  python2Full
  rpm
  skype
  powertop
  socat
  nmap # `ncat`
  iptables
  bridge-utils
  lxc
  openvswitch
  dnsmasq
  dhcpcd
  dhcp
  bind
  pciutils
  awscli
  #aws-shell
  peco
  fzf
  #skim
  stunnel
  #colordiff # TODO: fix url in nixpkgs
  ncdu
  di
  graphviz
  gtypist
  nix-repl
  zip
  vifm
  wget
  unzip
  hdparm
  libsysfs
  iomelt
  htop
  jq
  binutils
  psmisc
  tree
  silver-searcher
  vimHuge
  vis
  emacs
  git
  cvs
  cvs_fast_export
  bazaar
  mercurialFull
  darcs
  subversion
  zsh
  tmux
  nix-prefetch-scripts
  mc
  watchman
  pythonPackages.pywatchman
  ctags
  global
  rtags
  w3m-full
  jdk
  leiningen
  tweak
  asciinema
  mongodb-tools
  clac
  #smem # get matplotlib integration working

  fuse
  sshfsFuse

  gtk2 # To get GTK+'s themes.
  gnome3.defaultIconTheme
  hicolor_icon_theme
  tango-icon-theme
  shared_mime_info
  vanilla-dmz

  networkmanagerapplet
  blueman
  pavucontrol

  # xosview2
  # rtv
  # fd
  # nullmailer
  # gradio
  # hstr
  # pgpdump
  # kt
  # proot
  # snd
  # biboumi
  # tzupdate
  # https://github.com/dino/dino
  # notify-desktop
  # xpointerbarrier
  # bcc
  # firehol
  # et
  # bro
  # fzy
  # iprange
  # gitinspector
  lr
  xe
  nq
  taskwarrior
  pagemon
  ripgrep
  exa
  vnstat
  playerctl
  # clipgrab diffoscope
  # ezstream
  # hotspot
  # abduco
  # dvtm
  # nix-index
  # lcdproc
  # aws-auth
  # gpick # TODO: package (https://github.com/thezbyg/gpick)
  # qdirstat
  # wiggle
  # darkhttp
  # unrar
]

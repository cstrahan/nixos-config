# http://loicpefferkorn.net/2015/01/arch-linux-on-macbook-pro-retina-2014-with-dm-crypt-lvm-and-suspend-to-disk/
# https://wiki.archlinux.org/index.php/Intel_graphics#Module-based_Powersaving_Options
# https://bbs.archlinux.org/viewtopic.php?id=199388

# TODO:
#  * pulseaudio-dlna

# https://developer.chrome.com/extensions/external_extensions
# https://developer.chrome.com/extensions/nativeMessaging
# https://developer.chrome.com/extensions/messaging
# https://developer.mozilla.org/en-US/Add-ons/WebExtensions/Native_messaging

{ config, lib, pkgs, ... }:

# Per-machine settings.
let
  meta = import ./meta.nix;
  isMBP = meta.hostname == "cstrahan-mbp-nixos"
       || meta.hostname == "cstrahan-work-mbp-nixos";
  isWork = meta.hostname == "cstrahan-work-mbp-nixos";
  isNvidia = meta.productName != "MacBookPro11,5";
  gitit = import ./private/gitit.nix;

in

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./modules
    #./nginx.nix
  ];

  system.stateVersion = "17.09";

  # Use the gummiboot efi boot loader.
  #boot.kernelPatches = [ pkgs.kernelPatches.ubuntu_fan_4_4 ];
  #boot.kernelPackages = pkgs.linuxPackages_4_4;
  boot.kernelModules = [ "msr" "coretemp" ] ++ lib.optional isMBP "applesmc";
  boot.blacklistedKernelModules =
    # make my desktop use the `wl` module for WiFi.
    lib.optionals (!isMBP) [ "b43" "bcma" "bcma-pci-bridge" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 8;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches"   = 1048576;   # default:  8192
    "fs.inotify.max_user_instances" =    1024;   # default:   128
    "fs.inotify.max_queued_events"  =   32768;   # default: 16384
  };

  # Select internationalisation properties.
  time.timeZone = "US/Eastern";
  i18n.consoleUseXkbConfig = true;
  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      table
      table-others # for LaTeX input
      m17n
      uniemoji # ibus 1.5.14 has emoji support, so maybe not necessary
    ];
  };

  networking.hostName = meta.hostname;
  networking.hostId = "0ae2b4e1";

  networking.networkmanager.enable = lib.mkForce true;
  networking.networkmanager.insertNameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.wireless.enable = lib.mkForce false;
  networking.firewall.enable = false;
  networking.firewall.allowedUDPPorts = [
    631 # IPP - printer discovery
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "devicemapper";

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    cpu.amd.updateMicrocode = false;
    facetimehd.enable = true;
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages = with pkgs; [ vaapiIntel libvdpau-va-gl vaapiVdpau ];
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiIntel libvdpau-va-gl vaapiVdpau ];
    pulseaudio.package = pkgs.pulseaudioFull; # 'full' instead of 'light' for e.g. bluetooth
    pulseaudio.enable = true;
    pulseaudio.support32Bit = true;
    pulseaudio.daemon.config = {
      flat-volumes = "no";
    };
    bluetooth.enable = true;
  };

  #programs.cdemu.enable = true;
  programs.light.enable = true;
  programs.ssh.startAgent = false; # we'll use GPG from ~/.xsession
  #programs.browserpass.enable = true;
  programs.gnupg = {
    # TODO: https://bbs.archlinux.org/viewtopic.php?id=214268
    agent.enable = true;
    agent.enableSSHSupport = true;
    agent.enableExtraSocket = false;
    agent.enableBrowserSocket = false;
    dirmngr.enable = true;
  };

  services.udev.packages = [
    pkgs.openocd # embedded dev devices
  ];

  services.logind.extraConfig =
    # I hate accidentally hitting the power key and watching my laptop die ...
    lib.optionalString isMBP ''
      HandlePowerKey=suspend
    '';

  environment.enableDebugInfo = false; # TODO

  environment.extraOutputsToInstall = [ /* "doc" "info" "devdoc" */ ]; # TODO

  environment.pathsToLink = [
    # Needed for GTK themes.
    "/share"
  ];

  environment.variables = {
    BROWSER = "google-chrome-stable";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";

    # Prevent Wine from changing filetype associations.
    # https://wiki.winehq.org/FAQ#How_can_I_prevent_Wine_from_changing_the_filetype_associations_on_my_system_or_adding_unwanted_menu_entries.2Fdesktop_links.3F
    WINEDLLOVERRIDES = "winemenubuilder.exe=d";
  };

  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  # Enable the backlight on rMBP
  # Disable USB-based wakeup
  # see: https://wiki.archlinux.org/index.php/MacBookPro11,x
  systemd.services.mbp-fixes = {
    description = "Fixes for MacBook Pro";
    wantedBy = [ "multi-user.target" "post-resume.target" ];
    after = [ "multi-user.target" "post-resume.target" ];
    script = ''
      if [[ "$(cat /sys/class/dmi/id/product_name)" == "MacBookPro11,3" ]]; then
        if [[ "$(${pkgs.pciutils}/bin/setpci  -H1 -s 00:01.00 BRIDGE_CONTROL)" != "0000" ]]; then
          ${pkgs.pciutils}/bin/setpci -v -H1 -s 00:01.00 BRIDGE_CONTROL=0
        fi
        echo 5 > /sys/class/leds/smc::kbd_backlight/brightness

        if ${pkgs.gnugrep}/bin/grep -q '\bXHC1\b.*\benabled\b' /proc/acpi/wakeup; then
          echo XHC1 > /proc/acpi/wakeup
        fi
      fi
    '';
    serviceConfig.Type = "oneshot";
  };

  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
      pkgs.cups-bjnp
      pkgs.hplip
      pkgs.cnijfilter2
    ];
  };

  #services.mbpfan.enable = true; # seems to have stopped working recently...
  services.xserver = {
    enable = true;
    wacom.enable = true;
    autorun = true;
    #videoDrivers = [ "nouveau" ];
    videoDrivers = lib.optional isNvidia "nvidia" ++
                   lib.optional (!isNvidia) "radeon";
    xkbOptions = "ctrl:nocaps";

    autoRepeatDelay = 200;
    autoRepeatInterval = 33; # 30hz

    deviceSection = ''
      Option   "NoLogo"         "TRUE"
      Option   "DPI"            "96 x 96"
      Option   "Backlight"      "gmux_backlight"
      Option   "RegistryDwords" "EnableBrightnessControl=1"
    '';

    # Settings can be tested out like so:
    #
    # $ synclient AccelFactor=0.0055 MinSpeed=0.95 MaxSpeed=1.15
    synaptics.enable = true;
    synaptics.twoFingerScroll = true;
    synaptics.buttonsMap = [ 1 3 2 ];
    synaptics.tapButtons = false;
    synaptics.accelFactor = "0.0055";
    synaptics.minSpeed = "0.95";
    synaptics.maxSpeed = "1.15";
    synaptics.palmDetect = true;
    synaptics.palmMinWidth = 10;
    # seems to default to 70 and 75
    synaptics.additionalOptions = ''
      Option "FingerLow" "80"
      Option "FingerHigh" "85"
    '';

    #desktopManager.kde4.enable = true;
    #displayManager.kdm.enable = true;
    #desktopManager.default = "kde4";

    desktopManager.default = "none";
    desktopManager.xterm.enable = false;
    displayManager.slim = {
      enable = true;
      defaultUser = "cstrahan";
      extraConfig = ''
        console_cmd ${pkgs.rxvt_unicode_with-plugins}/bin/urxvt -C -fg white -bg black +sb -T "Console login" -e ${pkgs.shadow}/bin/login
      '';
      theme = ./slim-theme;
    };
    windowManager.default = "xmonad";
    windowManager.xmonad.enable = true;
    windowManager.xmonad.extraPackages = hpkgs: [
      hpkgs.taffybar
      hpkgs.xmonad-contrib
      hpkgs.xmonad-extras
    ];

    displayManager.sessionCommands = ''
      # Set GTK_DATA_PREFIX so that GTK+ can find the themes
      export GTK_DATA_PREFIX=${config.system.path}

      # find theme engines
      export GTK_PATH=${config.system.path}/lib/gtk-3.0:${config.system.path}/lib/gtk-2.0

      # Find the mouse
      export XCURSOR_PATH=~/.icons:~/.nix-profile/share/icons:/var/run/current-system/sw/share/icons

      ${pkgs.xorg.xset}/bin/xset r rate 220 50

      if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        eval "$(${pkgs.dbus.out}/bin/dbus-launch --sh-syntax --exit-with-session)"
        export DBUS_SESSION_BUS_ADDRESS
      fi
    '';
  };

  #services.gitlab.enable = true;
  #services.gitlab.databasePassword = "gitlab";

  services.dbus.enable = true;
  services.upower.enable = true;

  services.redshift.enable = true;
  services.redshift.latitude = "39";
  services.redshift.longitude = "-77";
  services.redshift.temperature.day = 5500;
  services.redshift.temperature.night = 2300;

  services.actkbd.enable = true;
  services.actkbd.bindings = [
    { keys = [ 224 ]; events = [ "key" "rep" ]; command = "${pkgs.light}/bin/light -U 4"; }
    { keys = [ 225 ]; events = [ "key" "rep" ]; command = "${pkgs.light}/bin/light -A 4"; }
    { keys = [ 229 ]; events = [ "key" "rep" ]; command = "${pkgs.kbdlight}/bin/kbdlight down"; }
    { keys = [ 230 ]; events = [ "key" "rep" ]; command = "${pkgs.kbdlight}/bin/kbdlight up"; }
  ];

  services.mongodb.enable = true;
  services.zookeeper.enable = true;
  services.apache-kafka.enable = true;
  #services.elasticsearch.enable = true;
  #services.memcached.enable = true;
  services.redis.enable = true;
  systemd.services.redis.serviceConfig.LimitNOFILE = 10032;

  services.mesos.master = {
    advertiseIp = "127.0.0.1";
    enable = true;
    zk = "zk://localhost:2181/mesos";
  };

  services.mesos.slave = {
    enable = true;
    ip = "127.0.0.1";
    master = "127.0.0.1:5050";
    dockerRegistry = "/tmp/mesos/images/docker";
    executorEnvironmentVariables = {
      PATH = "/run/current-system/sw/bin";
    };
  };

  # Make sure to run:
  #  sudo createuser -s postgres
  #
  # If not running gitlab on localhost:
  #  sudo createuser -P gitlab
  #  sudo createdb -e -T template1 -O gitlab gitlab
  #services.postgresql.enable = true;
  #services.postgresql.package = pkgs.postgresql93;
  #services.postgresql.authentication = lib.mkForce ''
  #  # Generated file; do not edit!
  #  local all all              trust
  #  host  all all 127.0.0.1/32 trust
  #  host  all all ::1/128      trust
  #'';

  environment.systemPackages = import ./system-packages.nix pkgs;

  environment.shells = [
    "/run/current-system/sw/bin/zsh"
  ];

  users = {
    mutableUsers = false;
    extraGroups.docker.gid = lib.mkForce config.ids.gids.docker;
    extraUsers = [
      {
        uid             = 2000;
        name            = "cstrahan";
        group           = "users";
        extraGroups     = [ "wheel" "networkmanager" "docker" "fuse" ];
        isNormalUser    = true;
        passwordFile    = "/etc/nixos/passwords/cstrahan";
        useDefaultShell = false;
        shell           = "/run/current-system/sw/bin/zsh";
      }
    ];
  };

  nix.package = pkgs.nixUnstable.overrideAttrs (attrs:
    {
      src = pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nix";
        rev = "7a4d9574d9275426e31bb2b3fbb8515600d233c4";
        sha256 = "10gvxapaxkrm8jdv8s3lizv8sjswl57pnbb67bhgiin51skzv89k";
      };
    }
  );
  nix.useSandbox = true;
  # gc-keep-outputs in Nix 1.11, keep-outputs in Nix 1.12
  nix.extraOptions = ''
    keep-outputs = true
  '';
  nix.binaryCaches = [
    "https://cache.nixos.org"
    #"https://hydra.nixos.org" # <--- I think this is gone (???)
  ];
  nix.trustedBinaryCaches = [
    "https://cache.nixos.org"
    #"https://hydra.nixos.org"
  ];
  # https://github.com/NixOS/nixpkgs/issues/9129
  nix.requireSignedBinaryCaches = true;
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

  fonts = {
    fontconfig.enable = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      pragmatapro
      #proggyfonts # hash changed

      emojione
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      fira
      fira-code
      fira-mono
      font-droid

      hack-font
      terminus_font
      anonymousPro
      freefont_ttf
      corefonts
      dejavu_fonts
      inconsolata
      ubuntu_font_family
      ttf_bitstream_vera
    ];
  };

  services.cron.systemCronJobs = [
    "0 2 * * * root fstrim /"
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.dmenu.enableXft = true;
  nixpkgs.config.firefox = {
   enableGoogleTalkPlugin = true;
   enableAdobeFlash = true;
   enableAdobeFlashDRM = true;
   jre = false;
   icedtea = true;
  };
  nixpkgs.config.chromium = {
   enablePepperFlash = true;
   enableWideVine = true;
  };
  nixpkgs.config.packageOverrides = super: let self = super.pkgs; in
    rec {
      # https://github.com/NixOS/nixpkgs/issues/28106
      #optipng = super.optipng.overrideAttrs (drv: {
      #  preConfigure = ''
      #    export LD=$CC
      #  '';
      #});

      #iproute = super.iproute.override { enableFan = true; };
      linux_4_4 = super.linux_4_4.override {
        kernelPatches = super.linux_4_4.kernelPatches ++ [
          # self.kernelPatches.ubuntu_fan_4_4
        ] ++ lib.optionals (meta.productName == "MacBookPro11,5") [
          { name = "fix-mac-suspend"; patch = ./mac-suspend.patch; }
          { name = "fix-mac-backlight"; patch = ./mac-backlight-4.4.patch; }
        ];
      };

      kdbplus = super.kdbplus.overrideAttrs (_: {
        src = self.requireFile {
          message = ''
            Nix can't download kdb+ for you automatically. Go to
            http://kx.com and download the free, 32-bit version for
            Linux. Then run "nix-prefetch-url file:///linux.zip" in the
            directory where you saved it. Note you need version 3.3.
          '';
          name   = "linux.zip";
          sha256 = "0pvndlqspxrzp5fbx2b6qw8cld8c8hcz5kavmgvs9l4s3qv9ab51";
        };
      });

      # Until v1.9.0 is released
      ranger = super.ranger.overrideAttrs (attrs: rec {
        name = "ranger-unstable-${version}";
        version = "2017-06-22";
        src = (self.fetchFromGitHub {
                 owner = "ranger";
                 repo = "ranger";
                 rev = "086074db6f08af058ffdced7319287715a88d42a";
                 sha256 = "0mfcjaaqwkn8kwnr67v9g2mqrvamxsn73qz4zxjdfdqswkbyjyhk";
               });
      });

      pragmatapro =
        self.stdenv.mkDerivation rec {
          version = "0.820";
          name = "pragmatapro-${version}";
          src = self.requireFile rec {
            name = "PragmataPro${version}.zip";
            url = "file://path/to/${name}";
            sha256 = "0dg7h80jaf58nzjbg2kipb3j3w6fz8z5cyi4fd6sx9qlkvq8nckr";
          };
          buildInputs = [ self.unzip ];
          phases = [ "installPhase" ];
          installPhase = ''
            unzip $src

            install_path=$out/share/fonts/truetype/public/pragmatapro-$version
            mkdir -p $install_path

            find -name "PragmataPro*.ttf" -exec mv {} $install_path \;
          '';
        };

      vimHuge =
        with self;
        with self.xorg;
        stdenv.mkDerivation rec {
          name = "vim-${version}";

          version = "8.0.0005";

          dontStrip = 1;

          hardeningDisable = [ "fortify" ];

          src = fetchFromGitHub {
            owner = "vim";
            repo = "vim";
            rev = "v${version}";
            sha256 = "0ys3l3dr43vjad1f096ch1sl3x2ajsqkd03rdn6n812m7j4wipx0";
          };

          buildInputs = [
            pkgconfig gettext glib
            libX11 libXext libSM libXpm libXt libXaw libXau libXmu libICE
            gtk2 ncurses
            cscope
            python2Full ruby luajit perl tcl
          ];

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
        };
    };

    # https://wiki.archlinux.org/index.php/Systemd/User#D-Bus
    #systemd.services."user@".environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/%I/bus";
    #systemd.user.sockets."dbus" = {
    #  description = "D-Bus User Message Bus Socket";
    #  wantedBy = [ "sockets.target" ];
    #  socketConfig = {
    #    ListenStream = "%t/bus";
    #  };
    #};
    #systemd.user.services."dbus" = {
    #  description = "D-Bus User Message Bus";
    #  requires = [ "dbus.socket" ];
    #  serviceConfig = {
    #    ExecStart = "${pkgs.dbus_daemon}/bin/dbus-daemon --session --address=systemd: --nofork --nopidfile --systemd-activation";
    #    ExecReload = "${pkgs.dbus_daemon}/bin/dbus-send --print-reply --session --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig";
    #  };
    #};
}

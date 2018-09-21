# https://blog.pclewis.com/2016/03/19/xmonad-spacemacs-style.html
# https://github.com/pclewis/dotfiles/tree/master/xmonad/.xmonad
# https://hoodoo.github.io/
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
  ];

  system.stateVersion = "18.09";

  #services.kubernetes.roles = [ "master" "node" ];
  #services.kubernetes.kubelet.hostname = "localhost";

  #services.gitit.enable = true;
  #services.gitit.port = 80;
  #services.gitit.oauthClientId = gitit.oauthClientId;
  #services.gitit.oauthClientSecret = gitit.oauthClientSecret;
  #services.gitit.oauthCallback = "http://wiki.cstrahan.com/_githubCallback";
  #services.gitit.oauthAuthorizeEndpoint = "https://github.com/login/oauth/authorize";
  #services.gitit.oauthAccessTokenEndpoint = "https://github.com/login/oauth/access_token";
  #services.gitit.authenticationMethod = "github";

  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.timeout = 8;
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # don't depend on NVRAM
    device = "nodev"; # EFI only
    extraEntries = ''
      menuentry "Ubuntu" {
        insmod fat
        insmod part_gpt
        insmod chain
        search --no-floppy --fs-uuid 67E3-17ED --set root
        chainloader /EFI/ubuntu/shimx64.efi
      }

      menuentry "rEFInd" {
        insmod fat
        insmod part_gpt
        insmod chain
        search --no-floppy --fs-uuid 67E3-17ED --set root
        chainloader /EFI/BOOT/refind_x64.efi
      }
    '';
  };

  boot.supportedFilesystems = [ "exfat" "btrfs" ];
  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches"   = 1048576;   # default:  8192
    "fs.inotify.max_user_instances" =    1024;   # default:   128
    "fs.inotify.max_queued_events"  =   32768;   # default: 16384
  };
  boot.kernelModules = [ "msr" "coretemp" ] ++ lib.optional isMBP "applesmc";
  boot.blacklistedKernelModules =
    # make my desktop use the `wl` module for WiFi.
    lib.optionals (!isMBP) [ "b43" "bcma" "bcma-pci-bridge" ];

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

  virtualisation.virtualbox.host.enable = true;
  # vbox 3D acceleration issue:  https://github.com/NixOS/nixpkgs/issues/22760
  virtualisation.virtualbox.host.enableHardening = false;

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

    # https://wiki.archlinux.org/index.php/Mouse_acceleration
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

    #desktopManager.plasma5.enable = true;
    #desktopManager.default = "plasma5";
    #displayManager.sddm.enable = true;

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
        extraGroups     = [ "wheel" "networkmanager" "docker" "fuse" "vboxusers" ];
        isNormalUser    = true;
        passwordFile    = "/etc/nixos/passwords/cstrahan";
        useDefaultShell = false;
        shell           = "/run/current-system/sw/bin/zsh";
      }
    ];
  };

  nix.package = pkgs.nixUnstable;
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
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "aarch64.nixos.community";
      maxJobs = 96;
      sshKey = "/root/.ssh/cstrahan_rsa";
      sshUser = "cstrahan";
      system = "aarch64-linux";
      supportedFeatures = [ "big-parallel" ];
    }
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

      iosevka
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
  nixpkgs.overlays = [
    (import ./overlays/packages.nix)

    (self: super: {
      # https://github.com/taffybar/taffybar/issues/367
      # https://github.com/NixOS/nixpkgs/issues/39493
      # https://github.com/NixOS/nixpkgs/pull/32787
      taffybar =
        let
          inherit (self.haskell.lib) addBuildDepend;
          hpkgs = pkgs.haskell.packages.ghc822.extend (self: super: {
            # https://github.com/NixOS/nixpkgs/pull/46766
            ListLike = addBuildDepend super.ListLike self.semigroups;

            # https://github.com/NixOS/nixpkgs/pull/46767
            gi-glib = super.gi-glib.override { haskell-gi-overloading = self.haskell-gi-overloading_0_0; };
            gi-cairo = super.gi-cairo.override { haskell-gi-overloading = self.haskell-gi-overloading_0_0; };
            gi-xlib = super.gi-xlib.override { haskell-gi-overloading = self.haskell-gi-overloading_0_0; };
          });

          taffybar-unwrapped = super.taffybar.override {
            inherit (hpkgs) ghcWithPackages;
          };
        in
          taffybar-unwrapped.overrideAttrs (drv: {
            nativeBuildInputs = drv.nativeBuildInputs or [] ++ [ self.makeWrapper ];
            buildCommand = drv.buildCommand + ''
              sed -i "2iexport GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" $out/bin/taffybar
            '';
          });

      # we want just the xembed-sni-proxy from plasma-workspace
      xembed-sni-proxy = self.runCommandNoCC "xembed-sni-proxy" {} ''
        mkdir -p $out/bin
        ln -s ${pkgs.plasma-workspace}/bin/xembedsniproxy $out/bin
      '';

      linux_4_4 = super.linux_4_4.override {
        kernelPatches = super.linux_4_4.kernelPatches ++ [
          # self.kernelPatches.ubuntu_fan_4_4
        ] ++ lib.optionals (meta.productName == "MacBookPro11,5") [
          { name = "fix-mac-suspend"; patch = ./mac-suspend.patch; }
          { name = "fix-mac-backlight"; patch = ./mac-backlight-4.4.patch; }
        ];
      };
    })
  ];
}

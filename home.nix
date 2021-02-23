{ lib, pkgs, ... }:

# inspired by modules/config/i18n.nix
with lib;

let

  inherit (pkgs.glibcLocales) version;

  archivePath = "${pkgs.glibcLocales}/lib/locale/locale-archive";

  # lookup the version of glibcLocales and set the appropriate environment vars
  localeVars = if versionAtLeast version "2.27" then {
    LOCALE_ARCHIVE_2_27 = archivePath;
  } else if versionAtLeast version "2.11" then {
    LOCALE_ARCHIVE_2_11 = archivePath;
  } else
    { };

  allVimPlugins =
    lib.mapAttrsToList (k: v: v) (removeAttrs pkgs.myVimPlugins ["override" "overrideDerivation"]);

in {

  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
    zathura.useMupdf = true; # disable to use poppler for rendering

    firefox = {
     enableGoogleTalkPlugin = true;
     enableAdobeFlash = true;
     enableAdobeFlashDRM = true;
     jre = false;
     icedtea = true;
    };
    chromium = {
     enableWideVine = true;
    };
  };
  nixpkgs.overlays = [
    (import ./overlays/packages.nix)
  ];

  home.stateVersion = "20.09";

  home.packages = allVimPlugins ++ [
    pkgs.neovim
    pkgs.vcprompt
    pkgs.git
  ];

  # Ensure LOCALE_ARCHIVE_2_27 is set for entire graphical environment.
  # Avoids problems like here:
  #
  #   /home/cstrahan/.nix-profile/bin/manpath: can't set the locale; make sure $LC_* and $LANG are correct
  #
  # See https://github.com/nix-community/home-manager/issues/432
  pam.sessionVariables = localeVars;
}

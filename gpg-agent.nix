# inspired by: https://github.com/ttuegel/nixos-config/blob/master/gpg-agent.nix
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gpg-agent;

        #. ${config.system.build.setEnvironment}
  startGpgAgent = pkgs.writeScript "start-gpg-agent"
    ''
        #!/bin/sh
        ${pkgs.gnupg21}/bin/gpg-agent \
            --enable-ssh-support \
            --pinentry-program ${pkgs.pinentry}/bin/pinentry-gtk-2 \
            --allow-loopback-pinentry \
            --daemon
    '';

in

{
  options = {

    programs.gpg-agent = {
      enable = mkEnableOption "gpg-agent";
    };

  };

  config = mkIf cfg.enable {

    programs.ssh.startAgent = mkDefault false;
    services.xserver.startGnuPGAgent = mkDefault false;

    systemd.user.services = {
      gpg-agent = {
        description = "Secret key management for GnuPG";
        enable = true;
        serviceConfig = {
          Type = "forking";
          ExecStart = "${startGpgAgent}";
          ExecStop = "${pkgs.procps}/bin/pkill -u %u gpg-agent";
          Restart = "always";
        };
        wantedBy = [ "default.target" ];
      };
    };

    environment.extraInit = ''
      if [ -n "$TTY" -o -n "$DISPLAY" ]; then
          ${pkgs.gnupg21}/bin/gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
      fi

      if [ -z "$SSH_AUTH_SOCK" ]; then
          export SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"
      fi
    '';

    assertions =
      [ { assertion = !(config.programs.ssh.startAgent && cfg.enable);
          message =
            ''
              The OpenSSH agent and this custom GnuPG agent cannot be started both. Please
              choose between ‘programs.ssh.startAgent’ and ‘programs.gpg-agent.enable’.
            '';
        }
        { assertion = !(config.services.xserver.startGnuPGAgent && cfg.enable);
          message =
            ''
              The default GnuPG agent and this custom GnuPG agent cannot be started both. Please
              choose between ‘services.xserver.startGnuPGAgent’ and ‘programs.gpg-agent.enable’.
            '';
        }
      ];

  };
}

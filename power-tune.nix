{ config, lib, pkgs, ... }:

{
  systemd.services.power-tune = {
    description = "Power Management tunings";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.powertop}/bin/powertop --auto-tune
      ${pkgs.iw}/bin/iw dev wlp3s0 set power_save on
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo powersave > $cpu
      done
    '';
    serviceConfig.Type = "oneshot";
  };
}

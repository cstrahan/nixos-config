{ config, lib, pkgs, inputs, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/794f932b-e213-4239-9d05-bc0d334e6506";
      fsType = "btrfs";
      options = [ "subvol=nixos/@" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/eb05cba0-5ead-42cd-b630-87799aefa10e";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/8FC3-FC3A";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 12;
}

{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.extraInstallCommands = ''
    set -euo pipefail
    cp --no-preserve=mode -r ${config.hardware.deviceTree.package} ${config.boot.loader.efi.efiSysMountPoint}/
    for filename in ${config.boot.loader.efi.efiSysMountPoint}/loader/entries/nixos*-generation-[1-9]*.conf; do
      if ! ${pkgs.gnugrep}/bin/grep -q 'devicetree' $filename; then
        echo "devicetree /dtbs/${config.hardware.deviceTree.name}" >> $filename
      fi
    done
  '';
}

{ config, lib, pkgs, modulesPath, ... }:

{
  fileSystems.${config.boot.loader.efi.efiSysMountPoint}.neededForBoot = true;
  fileSystems."/".autoResize = true;
  # boot.growPartition = true;

  system.build.efiImage =
    let
      toplevel = config.system.build.toplevel;

      rootImage = pkgs.callPackage (modulesPath + "/../lib/make-ext4-fs.nix") {
        storePaths = [ toplevel ];
        volumeLabel = "NIXOS_ROOT";
      };

      efiArch = pkgs.hostPlatform.efiArch;
      bootloader = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
      bootloaderDest = "${lib.strings.toUpper efiArch}.EFI";

      populateEspCommands = ''
        toEspName() {
          local file="$(realpath "$1")"
          local base="$(basename "$file")"
          local dir="$(dirname "$file")"
          local dirbase="$(basename "$dir")"
          echo -n "$dirbase-$base.efi"
        }

        mkdir -p esp/EFI/BOOT esp/EFI/nixos esp/loader/entries
        cp "${bootloader}" "esp/EFI/BOOT/BOOT${bootloaderDest}"
        echo "type1" > esp/loader/entries.srel

        kernelDest="$(toEspName "${toplevel}/kernel")"
        initrdDest="$(toEspName "${toplevel}/initrd")"

        cp --no-preserve=mode "${toplevel}/kernel" "esp/EFI/nixos/$kernelDest"
        cp --no-preserve=mode "${toplevel}/initrd" "esp/EFI/nixos/$initrdDest"
        cp --no-preserve=mode -r ${config.hardware.deviceTree.package} esp/dtbs

        cat > esp/loader/entries/initial-nixos.conf <<END
        title NixOS
        version 0
        linux /efi/nixos/$kernelDest
        initrd /efi/nixos/$initrdDest
        devicetree /dtbs/${config.hardware.deviceTree.name}
        options init=${toplevel}/init $(cat ${toplevel}/kernel-params)
        END
      '';

    in pkgs.callPackage ./make-efi-image {
      inherit rootImage populateEspCommands;
      skipSize = 1;
      espSize = 128;
    };

  boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      set -euo pipefail
      set -x
      # Register the contents of the initial Nix store
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
      rm -f /boot/loader/entries/initial-nixos.conf
      # Prevents this from running on later boots.
      rm -f /nix-path-registration
    fi
  '';

  assertions = [
    {
      assertion = config.boot.loader.systemd-boot.enable;
      message = "Building EFI Image requires systemd-boot";
    }
  ];
}

{ lib, config, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
  ];

  isoImage.isoName = let
    imageType = if (with pkgs.stdenv; hostPlatform == buildPlatform) then "native" else "cross";
    boardName = lib.removeSuffix ".dtb" (lib.last (lib.splitString "/" config.hardware.deviceTree.name));
  in
    "${config.isoImage.isoBaseName}-${imageType}-${boardName}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.squashfsCompression = "zstd -Xcompression-level 15";
}

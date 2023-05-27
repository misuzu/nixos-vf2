## Flash the bootloader via serial connection

This step may be optional.

Make the serial connection according to the section "Recovering the Bootloader" in <https://doc-en.rvspace.org/VisionFive2/PDF/VisionFive2_QSG.pdf>.
Flip the tiny switches towards the H (as opposed to L) marking on the PCB (towards edge of the board) as described that section (Step 2).
Power up, and assuming your serial device is `/dev/ttyUSB0`, run:

```shellSession
nix run github:misuzu/nixos-vf2#flash-visionfive2-vendor /dev/ttyUSB0
```

## Write a bootable SD card

An efi image can be created by building the `nixos-cross-image-efi` package:
```shell
nix build github:misuzu/nixos-vf2#nixos-cross-image-efi
```
The resulting image can be flashed to an SD card or an NVMe drive using `dd`:
```shell
sudo dd if=result/nixos-jh7110-starfive-visionfive-2-v1.3b.img of=/dev/your-disk bs=1M oflag=sync status=progress
```

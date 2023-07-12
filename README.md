## Flash the bootloader via serial connection

This step may be optional.

Make the serial connection according to the section "Recovering the Bootloader" in <https://doc-en.rvspace.org/VisionFive2/PDF/VisionFive2_QSG.pdf>.
Flip the tiny switches towards the H (as opposed to L) marking on the PCB (towards edge of the board) as described that section (Step 2).
Power up, and assuming your serial device is `/dev/ttyUSB0`, run:

```shellSession
nix run github:misuzu/nixos-vf2#flash-visionfive2-vendor /dev/ttyUSB0
```

If you have issues botting the SD image, try resetting u-boot environment variables using these commands (via UART):

```
env default -a
saveenv
```

## Write a bootable SD card

An efi image can be created by building the `nixos-cross-image-efi` package:

```shell
nix build github:misuzu/nixos-vf2#nixos-cross-image-efi
```

The resulting image can be flashed to an SD card using `dd`:

```shell
sudo dd if=result/nixos-cross-jh7110-starfive-visionfive-2-v1.3b.img of=/dev/your-disk bs=1M oflag=sync status=progress
```

## U-boot on an SD card

If you want to store vf2's firmware on an SD card, you need to partition it as follows:

```shell
# sgdisk is from gptfdisk package
sudo sgdisk -g --clear --set-alignment=1 \
--new=1:4096:8191 --change-name=1:'spl' --typecode=1:2e54b353-1271-4842-806f-e436d6af6985 \
--new=2:8192:40959 --change-name=2:'opensbi-uboot' --typecode=2:5b193300-fc78-40cd-8002-e86c45580b47 \
--new=3:40960:+256M --change-name=3:'efi' --typecode=3:C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
--largest-new=4 --change-name=4:'root' \
/dev/your-disk
```

After partitioning, write `u-boot-spl.bin.normal.out` to the first partition and `visionfive2_fw_payload.img` to the second partition.
```shell
sudo dd if=u-boot-spl.bin.normal.out of=/dev/your-disk1 bs=4096 status=progress
sudo dd if=visionfive2_fw_payload.img of=/dev/your-disk2 bs=4096 status=progress
```

Now use `dd` to copy efi and root partition from the image:
```shell
sudo losetup -P /dev/loop0 result/nixos-cross-jh7110-starfive-visionfive-2-v1.3b.img
sudo dd if=/dev/loop0p1 of=/dev/your-disk3 bs=1M status=progress
sudo dd if=/dev/loop0p2 of=/dev/your-disk4 bs=1M status=progress
sudo losetup -d /dev/loop0
```

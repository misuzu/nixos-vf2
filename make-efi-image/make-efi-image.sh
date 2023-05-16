mkdir -p "$out"
img="$out/efi-image.img"

rootSizeBlocks="$(du -B 512 --apparent-size "$rootImage" | awk '{ print $1 }')"
espSizeBlocks="$(( espSize * 1024 * 1024 / 512 ))"
imageSize=$(( rootSizeBlocks * 512 + espSizeBlocks * 512 + skipSize * 1024 * 1024 + 1024 * 1024 ))

truncate -s "$imageSize" "$img"

sfdisk "$img" <<EOF
  label: gpt

  start=${skipSize}M, size=${espSizeBlocks}, type=uefi
  start=$(( skipSize + espSize ))M, type=linux
EOF

eval "$(partx $img -o START,SECTORS --nr 2 --pairs)"
dd conv=notrunc if="$rootImage" of="$img" seek="$START" count="$SECTORS"

eval $(partx $img -o START,SECTORS --nr 1 --pairs)
truncate -s $((SECTORS * 512)) esp_part.img
mkfs.vfat --invariant -n NIXOS_EFI esp_part.img

mkdir esp
source "$populateEspCommandsPath"

find esp -exec touch --date=2000-01-01 {} +
# Copy the populated ESP into esp_part.img
cd esp
# Force a fixed order in mcopy for better determinism, and avoid file globbing
for d in $(find . -type d -mindepth 1 | sort); do
  faketime "2000-01-01 00:00:00" mmd -i ../esp_part.img "::/$d"
done
for f in $(find . -type f | sort); do
  mcopy -pvm -i ../esp_part.img "$f" "::/$f"
done
cd ..

# Verify the FAT partition before copying it.
fsck.vfat -vn esp_part.img
dd conv=notrunc if=esp_part.img of=$img seek=$START count=$SECTORS

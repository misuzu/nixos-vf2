{ runCommand, dosfstools, e2fsprogs, mtools, libfaketime, util-linux, zstd
, rootImage, skipSize, espSize, populateEspCommands
, imageName ? "efi-image.img"
}:

runCommand "efi-image" {
  nativeBuildInputs = [ dosfstools e2fsprogs libfaketime mtools util-linux zstd ];
  inherit rootImage skipSize espSize populateEspCommands;
  passAsFile = [ "populateEspCommands" ];
  env.IMAGE_NAME = imageName;
} ''
  source ${./make-efi-image.sh}
''

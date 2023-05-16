{ runCommand, dosfstools, e2fsprogs, mtools, libfaketime, util-linux, zstd
, rootImage, skipSize, espSize, populateEspCommands
}:

runCommand "efi-image" {
  nativeBuildInputs = [ dosfstools e2fsprogs libfaketime mtools util-linux zstd ];
  inherit rootImage skipSize espSize populateEspCommands;
  passAsFile = [ "populateEspCommands" ];
} ''
  source ${./make-efi-image.sh}
''

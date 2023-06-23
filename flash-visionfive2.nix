# https://github.com/MatthewCroughan/visionfive-nix/blob/master/visionfive2/README.md
{ writeScript
, writeShellScriptBin
, lrzsz
, picocom
, expect
, starfive-tools
, firmware-vf2
}:
let
  flashScript = writeScript "flash-script" ''
    #!${expect}/bin/expect -f
    set timeout -1
    spawn ${picocom}/bin/picocom [lindex $argv 0] -b 115200 -s "${lrzsz}/bin/sz -X"
    expect "CC"
    send "\x01\x13"
    expect "*** file:"
    send "${starfive-tools}/recovery/jh7110-recovery-20230322.bin"
    send "\r"
    expect "Transfer complete"

    # Wait for menu and install SPL
    expect "0: update 2ndboot/SPL in flash"
    send "0\r"

    expect "CC"
    send "\x01\x13"
    expect "*** file:"
    send "${firmware-vf2}/u-boot-spl.bin.normal.out"
    send "\r"
    expect "Transfer complete"

    # Wait for menu and install u-boot
    expect "2: update fw_verif/uboot in flash"
    send "2\r"
    expect "CC"
    send "\x01\x13"
    expect "*** file:"
    send "${firmware-vf2}/visionfive2_fw_payload.img"
    send "\r"
    expect "Transfer complete"

    # Wait for menu and exit
    expect "5: exit"
    send "5\r"
  '';
in writeShellScriptBin "flash-visionfive2" ''
  cat >&2 <<EOF
  NOTE: If you haven't already switched the boot mode
            - power off
            - flip the tiny switches towards the H (as opposed to L)
              marking on the PCB (towards edge of the board)

  EOF

  if [ ! -e $1 ]; then
    echo "Device $1 doesn't exist"
    exit 1
  fi

  if $(groups | grep --quiet --word-regexp "dialout"); then
    echo "User is in dialout group, flashing to board without sudo"
    ${flashScript} $1
  else
    echo "User is not in dialout group, flashing to board with sudo"
    sudo ${flashScript} $1
  fi

  cat >&2 <<EOF


  NOTE: If all went well, flip the switches back to the L (as opposed
        to H) marking on the PCB (away from edge of board).
  EOF
''

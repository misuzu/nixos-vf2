{ lib
, buildLinux
, ...
} @ args:

let
  modDirVersion = "6.4.0-rc2";
in
buildLinux (args // {
  inherit modDirVersion;
  version = "${modDirVersion}-vf2";

  structuredExtraConfig = with lib.kernel; {
    SERIAL_8250_DW = yes;
    PL330_DMA = no;
  };

  preferBuiltin = true;

  extraMeta = {
    branch = "visionfive2";
    maintainers = with lib.maintainers; [ nickcao ];
    description = "Linux kernel for StarFive's VisionFive2";
    platforms = [ "riscv64-linux" ];
  };
} // (args.argsOverride or { }))

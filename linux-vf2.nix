{ lib
, buildLinux
, ...
} @ args:

let
  modDirVersion = "6.4.0-rc4";
in
buildLinux (args // {
  inherit modDirVersion;
  version = "${modDirVersion}-vf2";

  structuredExtraConfig = with lib.kernel; {
    CPU_FREQ = yes;
    CPUFREQ_DT = yes;
    CPUFREQ_DT_PLATDEV = yes;
    DMADEVICES = yes;
    GPIO_SYSFS = yes;
    HIBERNATION = yes;
    NO_HZ_IDLE = yes;
    POWER_RESET_GPIO_RESTART = yes;
    PROC_KCORE = yes;
    PWM = yes;
    PWM_STARFIVE_PTC = yes;
    RD_GZIP = yes;
    SENSORS_SFCTEMP = yes;
    SERIAL_8250_DW = yes;
    SIFIVE_CCACHE = yes;
    SIFIVE_PLIC = yes;

    RTC_DRV_STARFIVE = yes;
    SPI_PL022 = yes;
    SPI_PL022_STARFIVE = yes;

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

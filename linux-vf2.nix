{ lib
, buildLinux
, fetchpatch
, ...
} @ args:

let
  modDirVersion = "6.4.0";
in
buildLinux (args // {
  inherit modDirVersion;
  version = "${modDirVersion}-vf2";

  kernelPatches = [
    # https://lore.kernel.org/all/20230524000012.15028-1-andre.przywara@arm.com/
    rec {
      name = "axp15060-1.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/all/20230524000012.15028-2-andre.przywara@arm.com/raw";
        hash = "sha256-kj4vQaT4CV29EHv8MtuTgM/semIPDdv2dmveo/X27vU=";
      };
    }
    rec {
      name = "axp15060-2.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/all/20230524000012.15028-3-andre.przywara@arm.com/raw";
        hash = "sha256-QCPQyKqoapMtqEDB9QgAuXA7n8e1OtG+YlIgeSQBxXM=";
      };
    }
    rec {
      name = "axp15060-3.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/all/20230524000012.15028-4-andre.przywara@arm.com/raw";
        hash = "sha256-SpKDm4PXR6qs7kX5SGVpFF/EPBijMhX1NsFUHrlCynM=";
      };
    }
  ];

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

    I2C = yes;
    MFD_AXP20X = yes;
    MFD_AXP20X_I2C = yes;
    REGULATOR_AXP20X = yes;

    # FATAL: modpost: drivers/gpu/drm/verisilicon/vs_drm: struct of_device_id is not terminated with a NULL entry!
    DRM_VERISILICON = no;

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

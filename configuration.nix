{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_vf2;
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200"
    "earlycon=sbi"
    "boot.shell_on_fail"
  ];
  boot.consoleLogLevel = 7;
  boot.initrd.availableKernelModules = [
    "dw_mmc-starfive" "motorcomm" "dwmac-starfive"
    "cdns3-starfive"
    "jh7110-trng"
    "phy-jh7110-usb"
    "clk-starfive-jh7110-aon"
    "clk-starfive-jh7110-stg"
    "clk-starfive-jh7110-vout"
    "clk-starfive-jh7110-isp"
    "clk-starfive-jh7100-audio"
    "phy-jh7110-pcie"
    "pcie-starfive"
    "nvme"
  ];

  hardware.deviceTree.name = "starfive/jh7110-starfive-visionfive-2-v1.3b.dtb";

  environment.systemPackages = with pkgs; [
    cryptsetup
    dtc
    fatresize
    git
    gptfdisk
    htop
    lshw
    mc
    mtdutils
    neofetch
    pciutils
    socat
    unzip
    usbutils
    wget
  ];

  services.getty.autologinUser = "root";
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users.mutableUsers = false;
  users.users.root.password = "secret";

  documentation.nixos.enable = false;

  system.stateVersion = "22.11";
}

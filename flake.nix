{
  nixConfig = {
    extra-substituters = [ "https://cache.ztier.in" ];
    extra-trusted-public-keys = [ "cache.ztier.link-1:3P5j2ZB9dNgFFFVkCQWT3mh0E+S3rIWtZvoql64UaXM=" ];
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-native.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs: {
    overlays.native-fixes = self: super: {
    };

    overlays.firmware = self: super: let
      recovery-bin = self.fetchurl {
        url = "https://github.com/starfive-tech/Tools/raw/0747c0510e090f69bf7d2884f44903b77b3db5c5/recovery/jh7110-recovery-20230322.bin";
        hash = "sha256-HIr7ftdgXnr1SFagIvgCGcqa1NrrDECjIPxHFj/52eQ=";
      };
    in {
      firmware-vf2-upstream = self.linkFarm "firmware-vf2-upstream" [
        {
          name = "jh7110-recovery.bin";
          path = recovery-bin;
        }
        {
          name = "u-boot-spl.bin.normal.out";
          path = "${super.ubootVisionFive2}/u-boot-spl.bin.normal.out";
        }
        {
          name = "visionfive2_fw_payload.img";
          path = "${super.ubootVisionFive2}/u-boot.itb";
        }
      ];

      firmware-vf2-vendor = self.linkFarm "firmware-vf2-vendor" [
        {
          name = "jh7110-recovery.bin";
          path = recovery-bin;
        }
        {
          name = "u-boot-spl.bin.normal.out";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/VisionFive2/releases/download/JH7110_VF2_515_v5.14.1/u-boot-spl.bin.normal.out";
            hash = "sha256-IE+VzNo1bkddIS1EIRGueqAIOajqQHfSMaFWpacqj3I=";
          };
        }
        {
          name = "visionfive2_fw_payload.img";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/VisionFive2/releases/download/JH7110_VF2_515_v5.14.1/visionfive2_fw_payload.img";
            hash = "sha256-ypQNtJspsPPibnvnr/hIa6g9G7YpScXm833UNim4Cug=";
          };
        }
      ];

      firmware-vf2-edk2-vendor = self.linkFarm "firmware-vf2-edk2-vendor" [
        {
          name = "jh7110-recovery.bin";
          path = recovery-bin;
        }
        {
          name = "u-boot-spl.bin.normal.out";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/edk2/releases/download/REL_VF2_JUN2023-stable202302/u-boot-spl.bin.normal.out";
            hash = "sha256-ep9gAbH3MJ9jDbYWKUaqyyluLVvmXJO5pI2tCtdSsb8=";
          };
        }
        {
          name = "visionfive2_fw_payload.img";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/edk2/releases/download/REL_VF2_JUN2023-stable202302/JH7110.fd";
            hash = "sha256-KgzB7hPEBPy53RsTgVnOXeAyZKmQD5/I6EBtDuSGYnE=";
          };
        }
      ];

      flash-visionfive2-upstream = self.callPackage ./flash-visionfive2.nix {
        firmware-vf2 = self.firmware-vf2-upstream;
      };

      flash-visionfive2-vendor = self.callPackage ./flash-visionfive2.nix {
        firmware-vf2 = self.firmware-vf2-vendor;
      };

      flash-visionfive2-edk2-vendor = self.callPackage ./flash-visionfive2.nix {
        firmware-vf2 = self.firmware-vf2-edk2-vendor;
      };
    };

    nixosConfigurations = {
      nixos-cross = inputs.nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              localSystem.system = "x86_64-linux";
              crossSystem.system = "riscv64-linux";
            };
          })
          ./configuration.nix
          ./hardware-configuration.nix
        ];
      };
      nixos-cross-image-efi = inputs.nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              localSystem.system = "x86_64-linux";
              crossSystem.system = "riscv64-linux";
            };
          })
          ./configuration.nix
          ./efi-image.nix
          ./hardware-configuration.nix
        ];
      };
      nixos-cross-image-iso = inputs.nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              localSystem.system = "x86_64-linux";
              crossSystem.system = "riscv64-linux";
            };
          })
          ./configuration.nix
          ./iso-image.nix
        ];
      };

      nixos-native = inputs.nixpkgs-native.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [
                inputs.self.overlays.native-fixes
              ];
            };
          })
          ./configuration.nix
          ./hardware-configuration.nix
        ];
      };
      nixos-native-image-efi = inputs.nixpkgs-native.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [
                inputs.self.overlays.native-fixes
              ];
            };
          })
          ./configuration.nix
          ./efi-image.nix
          ./hardware-configuration.nix
        ];
      };
      nixos-native-image-iso = inputs.nixpkgs-native.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [
                inputs.self.overlays.native-fixes
              ];
            };
          })
          ./configuration.nix
          ./iso-image.nix
        ];
      };
    };

    packages.x86_64-linux = let
      pkgsCross = import inputs.nixpkgs {
        overlays = [ inputs.self.overlays.firmware ];
        localSystem.system = "x86_64-linux";
        crossSystem.system = "riscv64-linux";
      };
      pkgs = import inputs.nixpkgs-native {
        system = "x86_64-linux";
        overlays = [ inputs.self.overlays.firmware ];
      };
      flash-visionfive2-upstream = pkgs.flash-visionfive2-upstream.override {
        firmware-vf2 = pkgsCross.firmware-vf2-upstream;
      };
    in {
      inherit flash-visionfive2-upstream;
      inherit (pkgs) flash-visionfive2-vendor;
      inherit (pkgs) flash-visionfive2-edk2-vendor;
      inherit (pkgs) firmware-vf2-vendor;
      inherit (pkgs) firmware-vf2-edk2-vendor;
      inherit (pkgsCross) firmware-vf2-upstream;
      nixos-cross = inputs.self.nixosConfigurations.nixos-cross.config.system.build.toplevel;
      nixos-cross-image-efi = inputs.self.nixosConfigurations.nixos-cross-image-efi.config.system.build.efiImage;
      nixos-cross-image-iso = inputs.self.nixosConfigurations.nixos-cross-image-iso.config.system.build.isoImage;
    };

    apps.x86_64-linux = {
      flash-visionfive2-upstream = {
        type = "app";
        program = "${inputs.self.packages.x86_64-linux.flash-visionfive2-upstream}/bin/flash-visionfive2";
      };
      flash-visionfive2-vendor = {
        type = "app";
        program = "${inputs.self.packages.x86_64-linux.flash-visionfive2-vendor}/bin/flash-visionfive2";
      };
    };
  };
}

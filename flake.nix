{
  nixConfig = {
    extra-substituters = [ "https://cache.ztier.in" ];
    extra-trusted-public-keys = [ "cache.ztier.link-1:3P5j2ZB9dNgFFFVkCQWT3mh0E+S3rIWtZvoql64UaXM=" ];
  };

  inputs = {
    nixpkgs = {
      url = "github:NickCao/nixpkgs/riscv";
    };
    nixpkgs-native = {
      url = "github:NixOS/nixpkgs/staging-next";
    };
    linux-vf2-src = {
      flake = false;
      url = "github:starfive-tech/linux/JH7110_VisionFive2_upstream";
    };
    starfive-tools = {
      flake = false;
      url = "github:starfive-tech/Tools";
    };
    uboot-vf2-src = {
      flake = false;
      url = "github:misuzu/u-boot/visionfive2";
    };
  };

  outputs = inputs: {
    overlays.default = self: super: {
      linuxPackages_vf2 = self.linuxPackagesFor (self.callPackage ./linux-vf2.nix {
        src = inputs.linux-vf2-src;
        kernelPatches = [ ];
      });
    };

    overlays.native-fixes = self: super: {
      bind = super.bind.overrideAttrs (old: {
        doCheck = false;
      });
      python311 = super.python311.override {
        packageOverrides = pyself: pysuper: {
          numpy = pysuper.numpy.overridePythonAttrs (_: {
            doCheck = false;
          });
        };
      };
    };

    overlays.firmware = self: super: {
      uboot-vf2 = (super.buildUBoot {
        version = inputs.uboot-vf2-src.shortRev;
        src = inputs.uboot-vf2-src;
        defconfig = "starfive_visionfive2_defconfig";
        filesToInstall = [
          "u-boot.itb"
          "spl/u-boot-spl.bin"
        ];
        makeFlags = [
          "CROSS_COMPILE=${super.stdenv.cc.targetPrefix}"
          "OPENSBI=${self.opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
        ];
      }).overrideAttrs (_: { patches = [ ]; });

      spl-tool = self.stdenv.mkDerivation {
        name = "spl-tool";
        src = inputs.starfive-tools;
        installPhase = ''
          runHook preInstall

          mkdir -p "$out/bin/"
          cp spl_tool "$out/bin/"

          runHook postInstall
        '';
        sourceRoot = "source/spl_tool";
      };

      firmware-vf2-upstream = self.stdenv.mkDerivation {
        name = "firmware-vf2-upstream";
        dontUnpack = true;
        nativeBuildInputs = [
          self.buildPackages.spl-tool
        ];
        installPhase = ''
          runHook preInstall

          cp ${self.uboot-vf2}/u-boot-spl.bin .
          spl_tool -c -f u-boot-spl.bin

          mkdir -p $out
          install -Dm444 u-boot-spl.bin.normal.out $out/u-boot-spl.bin.normal.out
          install -Dm444 ${self.uboot-vf2}/u-boot.itb $out/visionfive2_fw_payload.img

          runHook postInstall
        '';
      };

      firmware-vf2-vendor = self.linkFarm "firmware-vf2-vendor" [
        {
          name = "u-boot-spl.bin.normal.out";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/VisionFive2/releases/download/VF2_v3.1.5/u-boot-spl.bin.normal.out";
            hash = "sha256-O8+VZJQKu11I1K91dyJP4DjRt3qk+VnbxzDdeSHZLiM=";
          };
        }
        {
          name = "visionfive2_fw_payload.img";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/VisionFive2/releases/download/VF2_v3.1.5/visionfive2_fw_payload.img";
            hash = "sha256-kbxOSSIBCFIFPu1kzYAF9fghCHCaRqZR5EgkD9/H0iY=";
          };
        }
      ];

      firmware-vf2-edk2-vendor = self.linkFarm "firmware-vf2-edk2-vendor" [
        {
          name = "u-boot-spl.bin.normal.out";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/edk2/releases/download/REL_VF2_JUN2023/u-boot-spl.bin.normal.out";
            hash = "sha256-ep9gAbH3MJ9jDbYWKUaqyyluLVvmXJO5pI2tCtdSsb8=";
          };
        }
        {
          name = "visionfive2_fw_payload.img";
          path = self.fetchurl {
            url = "https://github.com/starfive-tech/edk2/releases/download/REL_VF2_JUN2023/JH7110.fd";
            hash = "sha256-KgzB7hPEBPy53RsTgVnOXeAyZKmQD5/I6EBtDuSGYnE=";
          };
        }
      ];

      flash-visionfive2-upstream = self.callPackage ./flash-visionfive2.nix {
        starfive-tools = inputs.starfive-tools;
        firmware-vf2 = self.firmware-vf2-upstream;
      };

      flash-visionfive2-vendor = self.callPackage ./flash-visionfive2.nix {
        starfive-tools = inputs.starfive-tools;
        firmware-vf2 = self.firmware-vf2-vendor;
      };

      flash-visionfive2-edk2-vendor = self.callPackage ./flash-visionfive2.nix {
        starfive-tools = inputs.starfive-tools;
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
              overlays = [ inputs.self.overlays.default ];
              localSystem.config = "x86_64-linux";
              crossSystem.config = "riscv64-linux";
            };
          })
          ./configuration.nix
          ./systemd-boot.nix
        ];
      };
      nixos-cross-image-efi = inputs.nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [ inputs.self.overlays.default ];
              localSystem.config = "x86_64-linux";
              crossSystem.config = "riscv64-linux";
            };
          })
          ./configuration.nix
          ./efi-image.nix
          ./systemd-boot.nix
        ];
      };
      nixos-cross-image-iso = inputs.nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [ inputs.self.overlays.default ];
              localSystem.config = "x86_64-linux";
              crossSystem.config = "riscv64-linux";
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
                inputs.self.overlays.default
                inputs.self.overlays.native-fixes
              ];
            };
          })
          ./configuration.nix
          ./systemd-boot.nix
        ];
      };
      nixos-native-image-efi = inputs.nixpkgs-native.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [
                inputs.self.overlays.default
                inputs.self.overlays.native-fixes
              ];
            };
          })
          ./configuration.nix
          ./efi-image.nix
          ./systemd-boot.nix
        ];
      };
      nixos-native-image-iso = inputs.nixpkgs-native.lib.nixosSystem {
        system = "riscv64-linux";
        modules = [
          ({ lib, config, pkgs, modulesPath, ... }: {
            nixpkgs = {
              overlays = [
                inputs.self.overlays.default
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
        localSystem.config = "x86_64-linux";
        crossSystem.config = "riscv64-linux";
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

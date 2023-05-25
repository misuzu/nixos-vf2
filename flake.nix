{
  inputs = {
    nixpkgs = {
      url = "github:NickCao/nixpkgs/riscv";
    };
    nixpkgs-native = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
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
        # FAIL: random_test
        doCheck = false;
      });
      libarchive = super.libarchive.overrideAttrs (old: {
        doCheck = false;
      });
      libressl = super.libressl.overrideAttrs (old: {
        doCheck = false;
      });
      meson = super.meson.overridePythonAttrs (old: {
        doCheck = false;
      });
      python310 = super.python310.override {
        packageOverrides = pyself: pysuper: {
          pytest-xdist = pysuper.pytest-xdist.overridePythonAttrs (_: {
            doCheck = false;
          });
        };
      };
    };

    overlays.firmware = self: super: {
      opensbi = super.opensbi.overrideAttrs (old: {
        src = super.fetchFromGitHub {
          version = "1.3-unstable";
          owner = "riscv-software-src";
          repo = "opensbi";
          rev = "dc1c7db05e075e0910b93504370b50d064a51402";
          sha256 = "sha256-pOpMgXBCU3X1LESczaOlEjRTIwC9myxqd8ZwHDgGnRc=";
        };
      });

      uboot-vf2 = (super.buildUBoot {
        version = inputs.uboot-vf2-src.shortRev;
        src = inputs.uboot-vf2-src;
        defconfig = "starfive_visionfive2_defconfig";
        filesToInstall = [
          "u-boot.itb"
          "spl/u-boot-spl.bin"
        ];
        extraMakeFlags = [
          "OPENSBI=${self.opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
        ];
      }).overrideAttrs (_: { patches = [ ./u-boot-boot-order.patch ]; });

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

      firmware-vf2 = self.stdenv.mkDerivation {
        name = "firmware-vf2";
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

      flash-visionfive2 = self.callPackage ./flash-visionfive2.nix {
        starfive-tools = inputs.starfive-tools;
        firmware-vf2 = self.firmware-vf2;
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
      flash-visionfive2 = pkgs.flash-visionfive2.override {
        firmware-vf2 = pkgsCross.firmware-vf2;
      };
    in {
      inherit flash-visionfive2;
      inherit (pkgsCross) firmware-vf2;
      nixos-cross = inputs.self.nixosConfigurations.nixos-cross.config.system.build.toplevel;
      nixos-cross-image-efi = inputs.self.nixosConfigurations.nixos-cross-image-efi.config.system.build.efiImage;
    };

    apps.x86_64-linux = {
      flash-visionfive2 = {
        type = "app";
        program = "${inputs.self.packages.x86_64-linux.flash-visionfive2}/bin/flash-visionfive2";
      };
    };
  };
}

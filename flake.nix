{
  description = "Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, ... }:
  let
    # 通用系统配置，可用于 NixOS 和 Darwin
    sharedConfiguration = { pkgs, config, ... }: {
      nixpkgs = {
        config.allowUnfree = true;
      };

      nix.settings.experimental-features = "nix-command flakes";
      system.stateVersion = 6;
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # 通用系统包
      environment.systemPackages = with pkgs; [
        # 开发工具
        neovim
        vscode
        bun
        python311

        # rust
        cargo
        rustc
        rust-analyzer
        rustfmt
        clippy

        # 终端工具
        fish
        tmux
        ripgrep
        eza
        helix

        # 字体
        nerd-fonts.roboto-mono
        nerd-fonts.jetbrains-mono
      ];

      # 通用路径配置
      environment.pathsToLink = [ "/bin" "/share/man" ];
    };

    # macOS 特定配置
    darwinConfiguration = { pkgs, config, ... }: {
      nixpkgs.hostPlatform = "aarch64-darwin";
      users.users.sontal.home = "/Users/sontal";

      # macOS 特定包
      environment.systemPackages = with pkgs; [
        alacritty
        mkalias
        obsidian
        google-chrome
        windsurf
        apktool
      ];

      # Homebrew 配置
      homebrew = {
        enable = true;
        brews = [
          "mas"
          "tcl-tk"
          "openssl"
          "gdbm"
        ];
        casks = [
          "iina"
          "orbstack"
          "cursor"
          "godot"
        ];
        taps = [
          "homebrew/cask"
        ];
        onActivation = {
          cleanup = "zap";
          upgrade = true;
        };
      };
      
      fonts.packages = with pkgs; [
        nerd-fonts.roboto-mono
        nerd-fonts.jetbrains-mono
      ];

      # macOS 系统设置
      system.defaults = {
        dock = {
          autohide = false;
          persistent-apps = [
            "${pkgs.alacritty}/Applications/Alacritty.app"
            "${pkgs.obsidian}/Applications/Obsidian.app"
            "${pkgs.code-cursor}/Applications/Cursor.app"
            "${pkgs.google-chrome}/Applications/Google Chrome.app"
            "/System/Applications/Mail.app"
            "/System/Applications/Launchpad.app"
          ];
        };
        finder.FXPreferredViewStyle = "clmv";
      };

      # Applications 文件夹管理
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
    };

    # Homebrew 模块配置
    homebrewModule = {
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "sontal";
        taps = {
          "homebrew/homebrew-core" = homebrew-core;
          "homebrew/homebrew-cask" = homebrew-cask;
          "homebrew/homebrew-bundle" = homebrew-bundle;
        };
        autoMigrate = true;
      };
    };

    # Home Manager 模块配置
    homeManagerModule = {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.sontal = import ./home/sontal.nix;
        extraSpecialArgs = { inherit inputs; };
      };
    };

    # 创建 Darwin 系统配置
    mkDarwinSystem = { system }: nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [ 
        sharedConfiguration
        darwinConfiguration
        nix-homebrew.darwinModules.nix-homebrew 
        homebrewModule
        home-manager.darwinModules.home-manager
        homeManagerModule
      ];
    };
  in
  {
    darwinConfigurations = {
      "Macbook-Pro" = mkDarwinSystem { system = "aarch64-darwin"; };
      "MacMini" = mkDarwinSystem { system = "aarch64-darwin"; };
    };
  };
}

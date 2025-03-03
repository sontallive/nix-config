{
  description = "Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    configuration = { pkgs, config, ... }: {
      # 基础系统配置
      nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = "aarch64-darwin";
      };

      nix.settings.experimental-features = "nix-command flakes";
      system.stateVersion = 6;
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # 系统包管理
      environment.systemPackages = with pkgs; [
        # 开发工具
        neovim
        vscode
	      bun
        

        # 终端工具
        alacritty
        fish
        tmux
        mkalias
        ripgrep
        eza

        # 字体
        nerd-fonts.roboto-mono
        nerd-fonts.jetbrains-mono

        # 应用程序
        obsidian
        google-chrome
        windsurf
        code-cursor
        apktool
      ];

      # Add these programs to the system PATH
      environment.pathsToLink = [ "/bin" "/share/man" ];
      
      # 配置字体 - 使用正确的选项
      fonts.packages = with pkgs; [
        nerd-fonts.roboto-mono
        nerd-fonts.jetbrains-mono
      ];
      
      users.users.sontal.home = "/Users/sontal";

      # macOS 系统偏好设置
      system.defaults = {
        dock = {
          autohide = false;
          # Make sure this setting is applied by using wipeAndPrepare
          persistent-apps = [
            "${pkgs.alacritty}/Applications/Alacritty.app"
            "${pkgs.obsidian}/Applications/Obsidian.app"
            # "${pkgs.vscode}/Applications/Visual Studio Code.app"
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
          # 设置应用程序链接
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
  in
  {
    darwinConfigurations."Macbook-Pro" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ 
        configuration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.sontal = import ./home/sontal.nix;
            # Add this to ensure Home Manager activates properly
            extraSpecialArgs = { inherit inputs; };
          };
        }
      ];
    };
    darwinConfigurations."MacMini" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ 
        configuration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.sontal = import ./home/sontal.nix;
            # Add this to ensure Home Manager activates properly
            extraSpecialArgs = { inherit inputs; };
          };
        }
      ];
    };
  };
}

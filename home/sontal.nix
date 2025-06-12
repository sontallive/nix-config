{ config, pkgs, ... }:

{
  # Home Manager 需要一个版本号
  home.stateVersion = "23.11";

  # 让 Home Manager 安装和管理自身
  programs.home-manager.enable = true;


  home.username = "sontal";
  home.homeDirectory = "/Users/sontal";

  # 用户特定的包
  home.packages = with pkgs; [
    # 开发工具
    git
    gh

    # CLI 工具
    ripgrep
    eza

    # 其他工具
    # ...
  ];

  # direnv
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };


  # 配置程序
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    # 添加您的 zsh 配置

    # Add eza aliases to zsh
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      claude = "~/.bun/bin/claude";
    };
  };

  # Git 配置
  programs.git = {
    enable = true;
    userName = "sontallive";
    userEmail = "418773551@qq.com";
    # 其他 Git 配置
  };

  # Bash configuration (if you use it)
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
    };
  };

  # Fish shell configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
    };

    # Make sure Fish can find system-installed Nix packages
    shellInit = ''
      # Add system Nix paths to Fish
      set -gx PATH /run/current-system/sw/bin $PATH

      # Also include user profile for other Nix packages
      set -gx PATH $HOME/.nix-profile/bin $PATH
      set -gx PATH $HOME/.cargo/bin $PATH
      set -gx PATH $HOME/.bun/bin $PATH
    '';

    # Fish functions if needed
    functions = {
      # Example function
      # fish_greeting = "echo Welcome to Fish, $(whoami)!";
    };

    # Add the foreign-env plugin to source bash files
    plugins = [
      {
        name = "foreign-env";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-foreign-env";
          rev = "dddd9213272a0ab848d474d0cbde12ad034e65bc";
          sha256 = "00xqlyl3lffc5l0viin1nyp819wf81fncqyz87jx8ljjdhilmgbs";
        };
      }
    ];
  };

  # 其他程序配置
  # ...

  # 文件配置
  home.file = {
    ".config/alacritty/alacritty.toml".source = ./dotfiles/alacritty.toml;
  };
}

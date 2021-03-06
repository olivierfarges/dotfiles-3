{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.git;

    userName = "Nicolas Berbiche";
    userEmail = "nic.berbiche@gmail.com";

    extraConfig = lib.mkMerge [
      {
        pull.ff = "only";
        push.default = "current";
        credential.helper = "gnome-keyring";
        merge.tool = "vimdiff";
        mergetool.prompt = true;
        difftool.prompt = false;
        diff.tool = "vimdiff";
      }
      (lib.mkIf config.programs.neovim.enable {
        # [mergetool "vimdiff"]
        "mergetool \"vimdiff\"" = {
          cmd = "${pkgs.neovim}/bin/nvim -d $LOCAL $REMOTE $MERGE -c 'wincmd w' -c 'wincmd J'";
        };
      })
    ];

    aliases = rec {
      b = "branch -vv";
      d = "diff";
      s = "show";
      f = "fetch --verbose";
      u = "reset HEAD";
      bn = "checkout -b";
      ch = "checkout";
      dc = "diff --cached";
      st = "status";
      cm = "commit --verbose";
      cma = "${cm} --amend";
      cmar = "${cma} --reuse-message=HEAD";
      cmare = "${cmar} --edit --verbose";
      # Pretty graph
      graph = "! git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
      # Shows the latest commit with more detail
      latest = "show HEAD --summary";
      # Prints all aliases
      aliases = "! git config --get-regexp '^alias\\.' | sed -e 's/^alias\\.//' -e 's/\\ /\\ =\\ /' | grep -v '^aliases' | sort";
      # Quick view of all recents commits for stand-ups
      oneline = "log --pretty=oneline";
      activity = "! git for-each-ref --sort=-committerdate refs/heads/"
                 + "--format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
      squash-all = ''!f(){ git reset $(git commit-tree HEAD^{tree} -m "''${1:-A new start}");};f'';
    };

    delta.enable = true;
    delta.options = [ "--dark" ];
  };
}

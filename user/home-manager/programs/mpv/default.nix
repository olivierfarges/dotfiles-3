{ config, lib, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
  };
  xdg.configFile."mpv/mpv.conf".source = ./mpv.conf;
  xdg.configFile."mpv/input.conf".source = ./input.conf;
  # Delete umpv socket/fifo
  systemd.user.tmpfiles.rules = [ "r %h/.umpv_fifo" "r %h/.umpv_socket" ];
}

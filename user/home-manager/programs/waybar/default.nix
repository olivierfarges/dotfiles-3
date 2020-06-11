{ config, lib, pkgs, ... }:

let
  cfg = config.programs.waybar;

  configText = builtins.toJSON { };
in
with lib;
with types;
{
  options.programs.waybar = mkOption {
    enable = mkEnableOption "Waybar";


    systemd = mkOption {
      description = "Systemd service integration";
      type = submodule {
        enable = mkEnableOption "Waybar Systemd";

        withSwayIntegration = mkOption {
          description = "Bind the systemd service to the 'sway-session.target` instead of 'graphical-session.target`";
          default = true;
          type = bool;
        };
      };
    };

    style = mkOption {
      description = ''
        CSS style of the bar.
        See <link xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration/>" for the documentation.
        '';
      default = null;
      type = nullOr str;
      example = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Source Code Pro;
        }
        window#waybar {
          background: #16191C;
          color: #AAB2BF;
        }
        #workspaces button {
          padding: 0 5px;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ pkgs.waybar ];

      xdg.configFile."waybar/config".text = configText;
    }
    (lib.mkIf (cfg.style != null) {
      xdg.configFile."waybar/style.css".text = cfg.style;
    })
    (lib.mkIf cfg.systemd.enable {
      systemd.user.services.waybar = {
        Unit = {
          Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "graphical-session.target" ];
          Requisite = [ "dbus.service" ];
          After = [ "dbus.service" ];
        };

        Service = {
          Type = "dbus";
          BusName = "fr.arouillard.waybar";
          ExecStart = "${pkgs.waybar}/bin/waybar";
          Restart = "always";
          RestartSec = "1sec";
        };

        Install = {
          WantedBy = [ (if cfg.systemd.withSwayIntegration then "sway-session.target" else "graphical-session.target") ];
        };
      };
    })
  ]);
}

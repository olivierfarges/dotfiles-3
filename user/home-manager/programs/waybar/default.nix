{ config, lib, pkgs, ... }:

with lib;
with lib.types;
let
  cfg = config.programs.waybar;

  isEmpty = list: if list == null then true else length list == 0;

  # Taken from <https://github.com/Alexays/Waybar/blob/adaf84304865e143e4e83984aaea6f6a7c9d4d96/src/factory.cpp>
  default-module-names = [
    "sway/mode" "sway/workspaces" "sway/window"
    "wlr/taskbar" "idle_inhibitor"
    "memory" "cpu" "clock" "disk" "tray"
    "network" "backlight"
    "pulseaudio" "mpd" "temperature" "bluetooth"
  ];

  isValidCustomModuleName = x: elem x default-module-names || (hasPrefix "custom/" x && stringLength x > 7);
  isValidModule = modules: all isValidCustomModuleName (attrNames modules);
  modules-definition = submodule {
    options = {
    };
  };
  modules-options = mkOption {
    description = "Modules configuration";
    type = addCheck modules-definition isValidModule;
  };

  # This type validates whether modules specified in modules-{left,center,right}
  # are defaults or have a valid name
  modules-names-type = let
    custom-modules = attrNames cfg.settings.modules;
    modules = unique (default-module-names ++ custom-modules);
  in enum modules;

  margins = let
    mkMargin = name: {
      "margin-${name}" = mkOption {
        description = "Margins value without unit";
        type = int;
        example = 10;
      };
    };
  in mkMerge (map mkMargin [ "top" "left" "bottom" "right" ]);
in
{
  options.programs.waybar = {
    enable = mkEnableOption "Waybar";

    settings = mkOption {
      description = ''
        Configuration for Waybar, see <link xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/>
        for supported values.
      '';
      default = null;
      example = literalExample
        ''
          [
            {
              layer = "top";
              position = "top";
              height = 30;
              # Specify outputs to restrict to certain outputs, otherwise show on all outputs
              output = [
                "eDP-1"
                "DP-1"
              ];
              modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
              modules-center = [ "sway/window" ];
              modules-right = [ "mpd" "custom/mymodule#with-css-id" "temperature" ];
              modules = {
                "sway/workspaces" = {

                };
                "custom/mymodule" = {

                };
              };
            }
          ]
        '';
      # not-todo: fix type when https://github.com/NixOS/nixpkgs/pull/75584 is merged
      type = nullOr (listOf (submodule {
        options = {
          layer = mkOption {
            description = "Decide if the bar is displayed in front (`top`) of the windows or behind (`bottom`)";
            type = enum [ "top" "bottom" ];
            example = "top";
          };

          output = mkOption {
            description = ''
              Specifies on which screen this bar will be displayed.
              Exclamation mark(!) can be used to exclude specific output.
            '';
            type = nullOr (either str (listOf str));
            example = literalExample ''
              [ "DP-1" "!DP-2" "!DP-3" ]
            '';
          };

          position = mkOption {
            description = "Bar position relative to the output";
            type = nullOr (enum [ "top" "bottom" "left" "right" ]);
            example = "right";
          };

          height = mkOption {
            description = "Height to be used by the bar if possible. Leave blank for a dynamic value";
            type = ints.unsigned;
          };

          width = mkOption {
            description = "Width to be used by the bar if possible. Leave blank for a dynamic value";
            type = nullOr ints.unsigned;
          };

          modules-left = mkOption {
            description = "Modules that will be displayed on the left";
            type = modules-names-type;
            default = [ ];
            example = literalExample ''
              [ "sway/workspaces" "sway/mode" "wlr/taskbar" ]
            '';
          };

          modules-center = mkOption {
            description = "Modules that will be displayed in the center";
            type = modules-names-type;
            default = [ ];
            example = literalExample ''
              [ "sway/window" ]
            '';
          };

          modules-right = mkOption {
            description = "Modules that will be displayed on the right";
            type = modules-names-type;
            default = [ ];
            example = literalExample ''
              [ "mpd" "custom/mymodule#with-css-id" "temperature" ]
            '';
          };

          modules = modules-options;

          margin = mkOption {
            description = "Margins value using the CSS format without units";
            type = str;
            example = "20 5";
          };

          inherit (margins) margin-top margin-left margin-bottom margin-right;

          name = mkOption {
            description = "Optional name added as a CSS class, for styling multiple waybars";
            type = str;
            example = "waybar-1";
          };

          gtk-layer-shell = mkOption {
            description = "Option to disable the use of gtk-layer-shell for popups";
            type = bool;
          };
        };
      }));
    };

    systemd = {
      enable = mkEnableOption "Waybar Systemd integration";

      withSwayIntegration = mkOption {
        description = "Bind the systemd service to the 'sway-session.target` instead of 'graphical-session.target`";
        default = true;
        type = bool;
      };
    };

    style = mkOption {
      description = ''
        CSS style of the bar.
        See <link xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration/>" for the documentation.
      '';
      default = null;
      type = nullOr str;
      example =
        ''
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

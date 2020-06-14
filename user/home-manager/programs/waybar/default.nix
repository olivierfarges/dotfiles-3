{ config, lib, pkgs, ... }:

with lib;
with lib.types;
let
  cfg = config.programs.waybar;

  # Used when generating warnings
  modulesPath = "programs.waybar.settings.modules";

  # Taken from <https://github.com/Alexays/Waybar/blob/adaf84304865e143e4e83984aaea6f6a7c9d4d96/src/factory.cpp>
  defaultModuleNames = [
    "sway/mode" "sway/workspaces" "sway/window"
    "wlr/taskbar" "idle_inhibitor"
    "memory" "cpu" "clock" "disk" "tray"
    "network" "backlight"
    "pulseaudio" "mpd" "temperature" "bluetooth"
  ];

  isValidCustomModuleName = x: elem x defaultModuleNames || (hasPrefix "custom/" x && stringLength x > 7);
  isValidModule = modules: all isValidCustomModuleName (attrNames modules);

  margins = let
    mkMargin = name: {
      "margin-${name}" = mkOption {
        type = nullOr int;
        default = null;
        example = 10;
        description = "Margins value without unit";
      };
    };
    margins = map mkMargin [ "top" "left" "bottom" "right" ];
  in foldl mergeAttrs {} margins;

  waybarBarConfig = submodule {
    options = {
      layer = mkOption {
        type = nullOr (enum [ "top" "bottom" ]);
        default = null;
        description = "Decide if the bar is displayed in front (`top`) of the windows or behind (`bottom`)";
        example = "top";
      };

      output = mkOption {
        type = nullOr (either str (listOf str));
        default = null;
        example = literalExample ''
              [ "DP-1" "!DP-2" "!DP-3" ]
            '';
        description = ''
              Specifies on which screen this bar will be displayed.
              Exclamation mark(!) can be used to exclude specific output.
            '';
      };

      position = mkOption {
        type = nullOr (enum [ "top" "bottom" "left" "right" ]);
        default = null;
        example = "right";
        description = "Bar position relative to the output";
      };

      height = mkOption {
        type = nullOr ints.unsigned;
        default = null;
        description = "Height to be used by the bar if possible. Leave blank for a dynamic value";
      };

      width = mkOption {
        type = nullOr ints.unsigned;
        default = null;
        description = "Width to be used by the bar if possible. Leave blank for a dynamic value";
      };

      modules-left = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = "Modules that will be displayed on the left";
        example = literalExample ''
              [ "sway/workspaces" "sway/mode" "wlr/taskbar" ]
            '';
      };

      modules-center = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = "Modules that will be displayed in the center";
        example = literalExample ''
              [ "sway/window" ]
            '';
      };

      modules-right = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = "Modules that will be displayed on the right";
        example = literalExample ''
              [ "mpd" "custom/mymodule#with-css-id" "temperature" ]
            '';
      };

      # modules = modules-options;
      modules = mkOption {
        type = addCheck attrs isValidModule;
        default = { };
        description = "Modules configuration";
        example = literalExample
          ''
            {
              "sway/window": {
                max-length = 50;
              };
              "clock": {
                format-alt = "{:%a, %d. %b  %H:%M}";
              };
              "custom/hello-from" = {
                format = "hello {}";
                max-length = 40;
                interval = 10;
                # You may be interested in using symlinkJoin to merge all scripts in one derivation
                # to have them all under one directory structure in the nix store
                exec = pkgs.writeScriptBin "hello-from-waybar" '''
                  #!${"\${pkgs.bash}/bin/bash"}
                  echo "from within waybar"
                ''';
              };
            }
          '';
      };

      margin = mkOption {
        type = nullOr str;
        default = null;
        description = "Margins value using the CSS format without units";
        example = "20 5";
      };

      inherit (margins) margin-top margin-left margin-bottom margin-right;

      name = mkOption {
        type = nullOr str;
        default = null;
        description = "Optional name added as a CSS class, for styling multiple waybars";
        example = "waybar-1";
      };

      gtk-layer-shell = mkOption {
        type = nullOr bool;
        default = null;
        description = "Option to disable the use of gtk-layer-shell for popups";
      };
    };
  };
in
{
  # meta.maintainers = [ hm.maintainers.berbiche ];

  options.programs.waybar = {
    enable = mkEnableOption "Waybar";

    settings = mkOption {
      description = ''
        Configuration for Waybar, see <link xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/>
        for supported values.
      '';
      default = [];
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
      # maybe-todo: improve type when https://github.com/NixOS/nixpkgs/pull/75584 is merged
      type = listOf waybarBarConfig;
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

  config = let
      # Inspired by https://github.com/NixOS/nixpkgs/pull/89781
      writePrettyJSON = name: x:
        pkgs.runCommandNoCCLocal name { } ''
          echo '${builtins.toJSON x}' | ${pkgs.jq}/bin/jq . > $out
        '';

      configSource = let
        # Removes nulls because Waybar ignores them for most values
        removeNulls = filterAttrs (_: v: !isNull v);
        # Makes the actual valid configuration Waybar accepts (strips our custom settings before converting to JSON)
        makeConfiguration = configuration: let
          # The "modules" option is not valid in the JSON as its descendants have to live at the top-level
          settingsWithoutModules = filterAttrs (n: _: n != "modules") configuration;
          settingsModules =
            if cfg.settings ? modules
            then cfg.settings.modules
            else { };
        in settingsWithoutModules // (removeNulls settingsModules);
        # The clean list of configurations
        finalConfiguration = map makeConfiguration cfg.settings;
      in writePrettyJSON "waybar-config.json" finalConfiguration;

      warnings = let
        mkPath = idx:
          let i = toString idx;
          in "${modulesPath}[definition ${i}-entry ${i}]";
        mkUnreferencedModuleWarning = idx: name:
          "The module '${name}' defined in '${mkPath idx}' is not referenced " +
          "in either `modules-left`, `modules-center` or `modules-right` of Waybar's options";
        mkUndefinedModuleWarning = idx: name:
          "The module '${name}' defined in '${mkPath idx}' is neither " +
          "a default module or a custom module declared in '${mkPath idx}.modules'";

        # Find all modules in `modules-{left,center,right}` and `modules` not declared/referenced.
        # cfg.settings is a list of Waybar configurations, we need to preserve the index for appropriate warnings
        allFaultyModules = flip imap1 cfg.settings (
          idx: settings: let
            allModules =
              concatMap (x: let v = settings."modules-${x}"; in if v != null then v else []) ["left" "center" "right"];
            nonDefaultModules = subtractLists defaultModuleNames allModules;
            declaredModules = if settings.modules != null then attrNames settings.modules else [];
            # Modules declared in `modules` but not referenced in `modules-{left,center,right}`
            unreferencedModules = subtractLists nonDefaultModules declaredModules;
            # Modules referenced in `modules-{left,center,right}` but not declared in `modules`
            undefinedModules = subtractLists declaredModules nonDefaultModules;
          in {
            idx = idx;
            undef = undefinedModules;
            unref = unreferencedModules;
          });

        allWarnings = flip concatMap allFaultyModules (
          { idx, undef, unref }: let
            undefined = map (mkUndefinedModuleWarning idx) undef;
            unreferenced = map (mkUnreferencedModuleWarning idx) unref;
          in undefined ++ unreferenced
        );
      in allWarnings;


    in # Emitted Nix configuration
      lib.mkIf cfg.enable (lib.mkMerge [
        {
          home.packages = [ pkgs.waybar ];
        }
        (lib.mkIf (cfg.settings != []) {
          # Generate warnings about defined but unreferenced modules
          inherit warnings;

          xdg.configFile."waybar/config".source = configSource;
        })
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

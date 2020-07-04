{ config, lib, pkgs, ... }:

let
  mkSwaybar = { outputs, id ? null }: {
    id = id;
    position = "top";
    mode = "dock";
    statusCommand = "while date +'%Y-%m-%d %l:%M:%S %p'; do sleep 1; done";
    trayOutput = "none";
    fonts = [ "FontAwesome 10" "Terminus 10" ];
    colors = {
      statusline = "#FFFFFF";
      background = "#323232";
      inactiveWorkspace = { border = "#000000"; background = "#5c5c5c"; text = "#FFFFFF"; };
    };
    extraConfig = lib.concatMapStringsSep "\n" (x: "output ${x}") outputs;
  };

  mkCommand = commands: lib.concatStringsSep "; \\\n" commands;

  mkFloatingNoBorder = { criteria, extraCommands ? [] }: {
    inherit criteria;
    command = mkCommand ([ "floating none" "border none" ] ++ extraCommands);
  };

  mkFloatingSticky = criteria: {
    inherit criteria;
    command = "sticky enable;";
  };

  mkInhibitFullscreen = criteria: {
    inherit criteria;
    command = "inhibit_idle fullscreen";
  };

  mkMarkSocial = name: criteria: {
    inherit criteria;
    command = "mark \"_social_${name}\"";
  };

  # Primary outputs
  OUTPUT-HOME-DELL-RIGHT = "Dell Inc. DELL U2414H R9F1P56N68VL";
  OUTPUT-HOME-DELL-LEFT  = "Dell Inc. DELL U2414H R9F1P55S45FL";
  OUTPUT-HOME-BENQ = "Unknown BenQ EW3270U 74J08749019";
  OUTPUT-LAPTOP = "eDP-1";

  # Sway variables
  scripts = config.home.homeDirectory + "/scripts";
  imageFolder = "${config.programs.swaylock.imageFolder}";

  terminal = "${pkgs.alacritty}/bin/alacritty --working-directory ${config.home.homeDirectory}";
  floating-term = "${terminal} --class='floating-term'";
  explorer = "${pkgs.nautilus}/bin/nautilus";
  browser = "${pkgs.dex}/bin/dex ${./firefox-desktop.nix}";
  lock = "${pkgs.swaylock}/bin/swaylock -f -c 0f0f0ff0 -i ${imageFolder}/3840x2160.png";
  logout = "${pkgs.wlogout}/bin/wlogout";
  audiocontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  menu = "${pkgs.xfce.xfce4-appfinder}/bin/xfce4-appfinder --replace";
  menu-wofi = "${pkgs.wofi}/bin/wofi --fork --show drun,run";

  WS1 = "1: browsing";
  WS2 = "2: school";
  WS3 = "3: dev";
  WS4 = "4: sysadmin";
  WS5 = "5: gaming";
  WS6 = "6: movie";
  WS7 = "7: social";
  WS8 = "8: random";
  WS9 = "9: random";
  WS10 = "10: random";



  config = lib.mkMerge [
    {
      inherit terminal;
      modifier = "Mod4";
      menu = menu-wofi;

      output = {
        "${OUTPUT-HOME-DELL-RIGHT}" = { bg = "${imageFolder}/1080x1920.png"; };
        "${OUTPUT-HOME-DELL-LEFT}"  = { bg = "${imageFolder}/1080x1920.png"; };
      };

      floating.criteria = [
        { app_id = "floating-term"; }
        { app_id = "org.gnome.Nautilus"; }
        { title = "feh.*/Pictures/screenshots/.*"; }
        { app_id = "firefox"; title = "Developer Tools"; }
      ];

      startup = [
        { command = "${pkgs.riot-desktop}/bin/riot-desktop"; }
        { command = "${pkgs.spotify}/bin/spotify"; }
        { command = "${pkgs.dex}/bin/dex ${config.xdg.configHome}/autostart/*"; }
        { command = "${pkgs.bitwarden}/bin/bitwarden"; }
      ];
    }
    {
      # Hopefully the windows are automatically focused...
      assigns = {
        # Games related
        "${WS5}" = [
          { instance = "Steam"; }
          { app_id = "lutris"; }
        ];
        # Movie related stuff
        "${WS6}" = [
          { title = "^Netflix.*"; class = "Chromium-browser"; }
          { name = "^Netflix.*"; }
          { title = "^Plex.*"; class = "Chromium-browser"; }
          { name = "^Plex.*"; }
        ];
        # Social stuff
        "${WS7}" = [
          { con_mark = "_social.*"; }
          { con_mark = "_music-player.*"; }
        ];
      };
    }
    {
      window.commands = lib.mkMerge [
        (map mkInhibitFullscreen [
          { class = "Firefox"; }
          { app_id = "firefox"; }
          { instance = "Steam"; }
          { app_id = "lutris"; }
          { name = "^Zoom Cloud.*"; }
        ])
        (map (x: mkFloatingNoBorder { criteria = x; }) [
          { app_id = "^launcher$"; }
          { app_id = "xfce4-appfinder"; }
          { instance = "xfce4-appfinder"; }
        ])
        (mkFloatingNoBorder {
          extraCommands = [ "scratchpad move" "scratchpad show" ];
          criteria = { app_id = "blueman-manager"; };
        })
        (map mkFloatingSticky [
          { app_id = "pavucontrol"; }
          { app_id = "gnome-calendar"; }
        ])
        {
          criteria = { class = "Spotify"; instance = "spotify"; };
          command = "mark --add \"_music-player.spotify\"";
        }
        (mkMarkSocial "riot" { class = "Riot"; })
        (mkMarkSocial "bitwarden" { class = "Bitwarden"; })
        (mkMarkSocial "rocket" { class = "Rocket.Chat"; })
        (mkMarkSocial "caprine" { class = "Caprine"; })
      ];
    }
    (mkSwaybar {
      id = "secondary-top";
      outputs = [ OUTPUT-HOME-DELL-RIGHT OUTPUT-HOME-DELL-LEFT ];
    })
  ];

  extraConfig = ''
    # Set default workspace outputs
    workspace ${WS5} output "${OUTPUT-HOME-BENQ}" "${OUTPUT-LAPTOP}"
    workspace ${WS6} output "${OUTPUT-HOME-BENQ}" "${OUTPUT-LAPTOP}"
  '';
in
{
  inherit config extraConfig;
}

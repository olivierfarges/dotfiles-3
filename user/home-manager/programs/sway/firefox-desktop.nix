builtins.toFile "firefox.desktop" ''
  [Desktop Entry]
  Type=Application
  Exec=env MOZ_DBUS_REMOTE=1 MOZ_ENABLE_WAYLAND=1 firefox %U
  Terminal=false
  Name=Firefox
  Categories=Application;Network;WebBrowser;
  Icon=firefox
  Comment=
  GenericName=Web Browser
  MimeType=x-scheme-handler/unknown;x-scheme-handler/about;text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp
''

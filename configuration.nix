{ config, pkgs, lib, ... }:

with builtins;
let
  pwd = toString ./.;
  sources = import ./nix/sources.nix;
  overlay = import ./overlays.nix;

  base-imports = map (x: ./nixos + "/${x}") [
    "hardware-configuration.nix"
    "cachix.nix"
    "zsh.nix"
    "graphical.nix"
    "all-packages.nix"
    "services.nix"
  ];
in
{
  imports = base-imports ++ [
    "${sources.home-manager}/nixos"
  ];

  options.my = with lib; {
    username = mkOption {
      type = types.str;
      description = "Primary user username";
      example = "nicolas";
      readOnly = true;
    };

    hostname = mkOption {
      type = types.str;
      description = "System hostname";
      readOnly = true;
    };

    userHomeConfiguration = mkOption {
      type = types.either types.path types.str;
      example = literalExample "./user/home.nix";
      description = "Path to the home-manager user configuration";
      readOnly = true;
    };
  };


  config = {
    nixpkgs.overlays = [ overlay ];

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "20.09"; # Did you read the comment?

    boot.cleanTmpDir = true;


    environment.systemPackages = [ pkgs.cachix ];
    nix = {
      allowedUsers = [ "@wheel" ];
      trustedUsers = [ "root" config.my.username ];
      nixPath = [ ("nixpkgs=" + toString pkgs.path) ];
      # Automatic GC of nix files
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 10d";
      };
    };
    # Define the nixos-config path to the current folder
    # nix.nixPath =
    #   [
    #     "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    #     "nixos-config=${pwd}/configuration.nix"
    #     "/nix/var/nix/profiles/per-user/root/channels"
    #   ];

    networking.hostName = config.my.hostname;
    networking.networkmanager.enable = true;

    # Virtualization
    virtualisation.docker.enable = true;

    time.timeZone = "America/Montreal";
    location.provider = "geoclue2";

    networking.firewall.enable = true;
    networking.nameservers = [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ];

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio = {
      enable = true;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      package = pkgs.pulseaudioFull;
      support32Bit = true;
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${config.my.username} = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      uid = 1000;
      group = "${config.my.username}";
      home = "/home/${config.my.username}";
      extraGroups = [ "wheel" "networkmanager" "input" "audio" "video" "docker" "dialout" ];
    };
    users.groups.${config.my.username} = {
      gid = 1000;
    };

    home-manager = {
      users."${config.my.username}" = config.my.userHomeConfiguration;
      useUserPackages = true;
      useGlobalPkgs = true;
      verbose = true;
    };
  };
}

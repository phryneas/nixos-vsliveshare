{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vsliveshare;
  pkg = pkgs.vsliveshare.override { enableDiagnosticsWorkaround = cfg.enableDiagnosticsWorkaround; };

  writableWorkaroundScript = import ./writableWorkaroundScript.nix { inherit pkgs lib config cfg; } ;

in {
  options.services.vsliveshare = with types; {
    enable = mkEnableOption "VS Code Live Share extension";
    enableWritableWorkaround = mkEnableOption "copying the build to the VS Code extension directory to ensure write access";
    enableDiagnosticsWorkaround = mkEnableOption "an UNIX socket that filters out the diagnostic logging done by VSLS Agent";

    extensionsDir = mkOption {
      type = str;
      example = "/home/user/.vscode/extensions";
      description = ''
        The VS Code extensions directory.
        CAUTION: The workaround will remove ms-vsliveshare.vsliveshare* inside this directory!
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ bash desktop-file-utils xlibs.xprop ]
      ++ optional (!cfg.enableWritableWorkaround) pkg;

    services.gnome3.gnome-keyring.enable = true;

    systemd.services.vsliveshare-writable-workaround = mkIf cfg.enableWritableWorkaround {
      description = "VS Code Live Share extension writable workaround";
      path = with pkgs; [ file ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = writableWorkaroundScript;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}

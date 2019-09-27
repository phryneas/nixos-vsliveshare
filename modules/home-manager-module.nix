{pkgs, lib, config, ...}:
with lib;
let
  livesharePkg = pkgs.callPackage liveshareGist {};
  cfg = config.services.vsliveshare;
  pkg = livesharePkg.override { enableDiagnosticsWorkaround = cfg.enableDiagnosticsWorkaround; };

  writableWorkaroundScript = import ./writableWorkaroundScript.nix { inherit pkgs lib config cfg; } ;

in {
  options.services.vsliveshare = with types; {
    enable = mkEnableOption "VS Code Live Share extension";
    enableWritableWorkaround = mkEnableOption "copying the build to the VS Code extension directory to ensure write access";
    enableDiagnosticsWorkaround = mkEnableOption "an UNIX socket that filters out the diagnostic logging done by VSLS Agent";

    extensionsDir = mkOption {
      type = str;
      default = "$HOME/.vscode/extensions";
      description = ''
        The VS Code extensions directory.
        CAUTION: The workaround will remove ms-vsliveshare.vsliveshare* inside this directory!
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ bash desktop-file-utils xlibs.xprop ];

    services.gnome-keyring.enable = true;

    systemd.user.services.vsliveshare-writable-workaround =  {
      Unit = {
        Description = "VS Code Live Share extension writable workaround";
        PartOf = [ "graphical-session-pre.target" ];
      };

      Service = {
        Environment = makeBinPath (with pkgs; [ file ]);
        ExecStart = writableWorkaroundScript;
      };

      Install = {
        WantedBy = [ "graphical-session-pre.target" ];
      };
    };
  };
}
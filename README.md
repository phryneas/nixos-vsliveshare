# Live Share support in Visual Studio Code for NixOS

Experimental support for Live Share in Visual Studio Code for NixOS. The need to modify the extension directory in a destructive way and most updates causing the patch files to no longer apply, makes it unsuitable for inclusion in the main Nixpkgs repository, so it is kept in its own repository until a better solution is found.

```nix
{ ... }:

{
  imports = [
    (builtins.fetchTarball {
      url = "https://github.com/msteen/nixos-vsliveshare/archive/e6ea0b04de290ade028d80d20625a58a3603b8d7.tar.gz";
      sha256 = "12riba9dlchk0cvch2biqnikpbq4vs22gls82pr45c3vzc3vmwq9";
    })
  ];

  services.vsliveshare = {
    enable = true;
    enableWritableWorkaround = true;
    enableDiagnosticsWorkaround = true;
    extensionsDir = "/home/matthijs/.vscode/extensions";
  };
}
```

## with home-manager

`ln -s $(realpath pkgs/overlay.nix) ~/.config/nixpkgs/overlays/`

```nix
 # home.nix
 imports = [
        /path/to/nixos-vsliveshare/modules/home-manager-module.nix
    ];

    services.vsliveshare = {
        enable = true;
        enableWritableWorkaround = true;
        enableDiagnosticsWorkaround = true;
        extensionsDir = "/home/user/.vscode-oss/extensions/";
    };
```

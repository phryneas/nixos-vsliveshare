{ config, lib, pkgs, cfg, ... }:

with lib;

let
  pkg = pkgs.vsliveshare.override { enableDiagnosticsWorkaround = cfg.enableDiagnosticsWorkaround; };
in pkgs.writeScript "vsliveshare-writable-workaround.sh" ''
    #!${pkgs.bash}/bin/bash

    out=${pkg}
    src=$out/share/vscode/extensions/ms-vsliveshare.vsliveshare

    # We do not want to pass any invalid path to `rm`.
    if [[ ! -d '${cfg.extensionsDir}' ]]; then
      echo "The VS Code extensions directory '${cfg.extensionsDir}' does not exist" >&2
      exit 1
    fi

    dst='${cfg.extensionsDir}'/ms-vsliveshare.vsliveshare-$(basename $out | sed 's/.*vsliveshare-//')

    # Only run the script when the build has actually changed.
    if [[ $(dirname "$(dirname "$(readlink "$dst/dotnet_modules/vsls-agent-wrapped")")") == $src ]]; then
      exit 0
    fi

    # Remove all previous versions of VS Code Live Share.
    find '${cfg.extensionsDir}' -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -exec rm -r {} \;

    # Create the extension directory.
    mkdir -p "$dst"

    cd "$src"

    # Copy over executable files and symlink files that should remain unchanged or that are ELF executables.
    executables=()
    while read -rd ''' file; do
      if [[ ! -x $file ]] || file "$file" | grep -wq ELF; then
        dst_file="$dst/$file"
        mkdir -p "$(dirname "$dst_file")"
        ln -s "$src/$file" "$dst_file"
      else
        executables+=( "$file" )
      fi
    done < <(find . -mindepth 1 -type f \( -executable -o -name \*.a -o -name \*.dll -o -name \*.pdb \) -printf '%P\0')
    cp --parents --no-clobber --no-preserve=mode,ownership,timestamps -t "$dst" "''${executables[@]}"
    chmod -R +x "$dst"

    # Copy over the remaining directories and files.
    find . -mindepth 1 -type d -printf '%P\0' |
      xargs -0r mkdir -p
    find . -mindepth 1 ! -type d ! \( -type f \( -executable -o -name \*.a -o -name \*.dll -o -name \*.pdb \) \) -printf '%P\0' |
      xargs -0r cp --parents --no-clobber --no-preserve=mode,ownership,timestamps -t "$dst"

    # Change the ownership of the files to that of the extension directory rather than root.
    chown -R --reference='${cfg.extensionsDir}' "$dst"
  ''

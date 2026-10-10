#!/bin/sh
set -eu
launcher=$0
case "$launcher" in /*) ;; *) launcher="$PWD/$launcher" ;; esac
links=0
while [ -L "$launcher" ]; do
  links=$((links + 1))
  [ "$links" -le 40 ] || { echo 'Switchboard launcher has too many symlinks.' >&2; exit 1; }
  target=$(readlink "$launcher")
  case "$target" in /*) launcher=$target ;; *) launcher="${launcher%/*}/$target" ;; esac
done
bin_dir=$(CDPATH= cd -- "${launcher%/*}" && pwd -P)
case "$bin_dir" in */bin) ;; *) echo 'Invalid Switchboard Homebrew bin directory.' >&2; exit 1 ;; esac
keg=${bin_dir%/bin}
formula_dir=${keg%/*}
case "$formula_dir" in */Cellar/switchboard) ;; *) echo 'Switchboard Homebrew launcher must be installed in its Cellar keg.' >&2; exit 1 ;; esac
brew_prefix=${formula_dir%/Cellar/switchboard}
export SWITCHBOARD_LAUNCHER="$brew_prefix/opt/switchboard/bin/switchboard"
export SWITCHBOARD_DISTRIBUTION=homebrew
exec "$brew_prefix/opt/switchboard/libexec/bin/switchboard" "$@"

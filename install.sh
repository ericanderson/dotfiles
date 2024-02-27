#!/bin/bash

# -e: exit on error
# -u: exit on unset variables
set -eu

if ! chezmoi="$(command -v chezmoi)"; then
  bin_dir="${HOME}/.local/bin"
  chezmoi="${bin_dir}/chezmoi"
  echo "Installing chezmoi to '${chezmoi}'" >&2
  if command -v curl >/dev/null; then
    chezmoi_install_script="$(curl -fsSL https://chezmoi.io/get)"
  elif command -v wget >/dev/null; then
    chezmoi_install_script="$(wget -qO- https://chezmoi.io/get)"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
  sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
  unset chezmoi_install_script bin_dir
fi

# Setup chezmoi variables if we can
if type "git" > /dev/null; then
    email="$(git config --global user.email || echo "")"
    
    if [ -z ${email} ]; then
        echo "Couldn't find an email. Skipping seeding chezmoi"
    else
        echo "Preseeding email to ${email}"
        export DOTFILES_EMAIL="${email}"
    fi
fi


# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

if [ -z ${var+x} ]; then
    echo "Not in a codespaces"
else
    echo "Linking dotfiles for chezmoi"
    ln -s "$script_dir" "$HOME/.local/share/chezmoi"
fi

set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
#!/bin/zsh
set -eo pipefail

cached=false
for arg in "$@"; do
  case $arg in
    --cached) cached=true ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# Check that nix is installed
if ! command -v nix &>/dev/null; then
  echo "Error: nix is not installed."
  echo ""
  echo "Install it with:"
  echo "  sh <(curl -L https://nixos.org/nix/install)"
  echo ""
  echo "Then restart your shell and re-run this script."
  exit 1
fi

# Check that nix-darwin is installed
if ! command -v darwin-rebuild &>/dev/null; then
  echo "Error: nix-darwin is not installed."
  echo ""
  echo "Install it with:"
  echo "  nix run nix-darwin -- switch --flake ~/.config/nix-darwin"
  echo "  (see https://github.com/LnL7/nix-darwin for full instructions)"
  echo ""
  echo "Then restart your shell and re-run this script."
  exit 1
fi

destination=nix-darwin
user_nix_dir=./users.d
defaults_file="${0:A:h}/.setup_defaults"

# fetch config
if $cached; then
  if [[ ! -d $destination ]]; then
    echo "Error: --cached specified but './$destination' does not exist."
    exit 1
  fi
  if [[ ! -z "$user_nix_dir/$USER.nix" ]]; then
    cp -r $user_nix_dir $destination
  fi
else
  if [[ -d $destination ]]; then
    read "confirm?Destination '$destination' already exists. Remove and re-clone? [y/N] "
    if [[ $confirm == [yY] ]]; then
      rm -rf $destination
    else
      echo "Aborting."
      exit 1
    fi
  fi
  nix flake clone --extra-experimental-features "nix-command flakes" github:the-evergive-project/nix-darwin --dest $destination
  if [[ ! -z "$user_nix_dir/$USER.nix" ]]; then
    cp -r $user_nix_dir $destination
  fi
fi
cd $destination

# fill in user-specific info
[[ -f $defaults_file ]] && source $defaults_file
read "new_display_name?Enter display name (eg. John Doe) [$display_name]: "
read "new_email?Enter email (eg. j.doe@evergive.com) [$email]: "
[[ -n $new_display_name ]] && display_name=$new_display_name
[[ -n $new_email ]] && email=$new_email
if [[ -n $new_display_name || -n $new_email ]]; then
  printf "display_name=%q\nemail=%q\n" "$display_name" "$email" >$defaults_file
fi
sed "s/{display_name}/$display_name/g; s/{username}/$(whoami)/g" flake.nix > flake.nix.tmp && mv flake.nix.tmp flake.nix

# setup ssh/age key
private_key="$HOME/.ssh/id_ed25519"
public_key="$private_key.pub"
age_key="$HOME/.config/sops/age/keys.txt"

if [[ ! -f $public_key ]]; then
  echo "generating ssh key..."
  ssh-keygen -t ed25519 -C "$email" -f "$private_key" -N ""
else
  echo "ssh key already exists"
fi

if [[ ! -f $age_key ]]; then
  echo "generating age key..."
  mkdir -p $HOME/.config/sops/age/
  nix-shell -p age --run "age-keygen < $public_key -o $age_key"
  age_pub="$(nix run --extra-experimental-features 'nix-command flakes' nixpkgs#ssh-to-age < "$public_key")"
  echo "share your key with the team: $age_pub"
else
  echo "age key already exists"
fi

echo "success"

# build the config
sudo nix run --extra-experimental-features "nix-command flakes" nix-darwin/master#darwin-rebuild -- switch --flake .#evergive

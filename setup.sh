#!/bin/zsh
set -o pipefail

destination=nix-darwin
user_nix_dir=./users.d

# fetch config
nix flake clone --extra-experimental-features "nix-command flakes" github:the-evergive-project/nix-darwin/amorrison/custom-config --dest $destination
if [[ ! -z "$user_nix_dir/$USER.nix" ]]; then
  cp -r $user_nix_dir $destination
fi
cd $destination

# fill in user-specific info
read "display_name?Enter display name (eg. John Doe): "
read "email?Enter email (eg. j.doe@evergive.com): "
sed -i '' "s/{display_name}/$display_name/g" flake.nix
sed -i '' "s/{username}/$(whoami)/g" flake.nix

set -o pipefail
read "email?Enter email (eg. j.doe@evergive.com): "

# setup ssh/age key
private_key="$HOME/.ssh/id_ed25519"
public_key="$private_key.pub"
age_key="$HOME/.config/sops/age/keys.txt"

if [[ ! -f $public_key ]]; then
  echo "generating ssh key..."
  ssh-keygen -t ed25519 -c "$email" -f "$private_key" -n ""
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

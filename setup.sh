#!/bin/zsh

destination=nix-darwin
experiments="--extra-experimental-features 'nix-command flakes'"

# fetch config
nix flake clone github:the-evergive-project/nix-darwin --dest $destination
cd $destination

# fill in user-specific info
read "display_name?Enter display name (eg. John Doe): "
read "email?Enter email (eg. j.doe@evergive.com): "
sed -i '' "s/{display_name}/$display_name/g" flake.nix
sed -i '' "s/{username}/$(whoami)/g" flake.nix

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
  nix $experiments run nixpkgs#ssh-to-age < "$public_key" -o "$age_key"
  age_pub="$(nix run nixpkgs#ssh-to-age < "$public_key")"
  echo "share your key with the team: $age_pub"
else
  echo "age key already exists"
fi

echo "success"

# build the config
sudo nix $experiments run nix-darwin/master#darwin-rebuild -- switch --flake .#evergive

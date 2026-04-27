## Nix Darwin for Evergive

This is a simple Nix repository that allows you to configure your local nix environment with Nix-darwin and home manager.

## First time run
The first time you will run this, you should run the `./setup.sh` file. This will ask you to provide your display name, email and laptop password for sudo access.

Please note that if you do not have sudo access to your computer, you will not be able to provision nix-darwin to it.

```bash
$ ./setup.sh
```

## User-specific configuration
If there is additional configuration you want for your local environment, you can use your `users.d/<username>.nix` file - note that `username` **must** match your local username (check `whoami` if you are unsure).

**Make sure you commit and push your changes when editing any configuration.**

## Updating flake (versions)
If you want to update any of the packages, you first need to run a flake update:
```bash
$ nix flake update
```

Then, you need to **push the generated flake.lock**. This is important because every time you run `./setup`, it pulls the repository and respects the content of the lock file.
```bash
$ git commit -m 'update lock file' && git push
```

Then, you can run the setup script again:
```bash
$ ./setup.sh
```

## Updating configuration
If you want to update your configuration, you should delete the existing `nix-darwin` folder and run setup again:
1. Delete the `nix-darwin` folder: `rm -rf ./nix-darwin`
1. Make your changes to your user's .nix file
1. Commit, push and merge your changes
1. Run setup: `./setup.sh`

If you want to iterate on changes locally without re-cloning from GitHub, use the `--cached` flag. This skips the clone step and uses the existing `./nix-darwin` folder as-is (errors if it does not exist):
```bash
$ ./setup.sh --cached
```

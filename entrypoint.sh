#!/bin/sh
set -eu

# Set abuild configuration
export PACKAGER="$INPUT_AUTHOR"
export REPODEST="$HOME/packages"
export PACKAGER_PRIVKEY="$HOME/$GITHUB_REPOSITORY_OWNER.rsa"

# Load RSA key
echo "$INPUT_RSA_PRIVATE_KEY" > "$HOME/$GITHUB_REPOSITORY_OWNER.rsa"
echo "$INPUT_RSA_PUBLIC_KEY" > "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub"
cp "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub" /etc/apk/keys

# Set current directory as a safe directory.
git config --global --add safe.directory /github/workspace
branch="$(git symbolic-ref --short HEAD)"

# Checkout gh-pages branch
if ! git fetch -n --no-recurse-submodules --depth=1 origin gh-pages; then
  echo "The branch gh-pages doesn't exist."
  exit 1
fi
git checkout --progress --force -B gh-pages refs/remotes/origin/gh-pages

# Copy current packages.
mkdir ~/packages
find . -type d -maxdepth 1 -mindepth 1 -not -path '*/.*' -exec cp -rf {} ~/packages/ \;
git checkout "$branch"

# Build any directory that contains an APKBUILD file
# shellcheck disable=SC2016
find . -type f -name APKBUILD -exec /bin/sh -c 'cd $(dirname {}); abuild -F checksum; abuild -F -r; git clean -dfx' \;

# Clean the repository and checkout the gh-pages branch
# Copy released files
git checkout gh-pages
cp "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub" .
cp -rf "$HOME"/packages/* .

# Add files and push the branch
git -c user.name="$GITHUB_ACTOR" -c user.email="$GITHUB_ACTOR@users.noreply.github.com" commit -am "${INPUT_COMMIT_MESSAGE:-Update packages}" && \
  git push origin gh-pages || echo Nothing to commit

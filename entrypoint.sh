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

# Generate index pages
generate_index() {
  dir=$1
  add_top_level=$2
  cd "$dir"
  files=$(find . -mindepth 1 -maxdepth 1 ! -name "$(printf "*\n*")" ! -name index.html ! -path '*/.*')
  env="$(mktemp)"
  cat <<EOF > "$env"
title='$GITHUB_ACTOR alpine packages'
files=['$files']
add_top_level=$add_top_level
EOF
  if "$add_top_level"; then
    echo "dir='$dir'" >> "$env"
  fi
  cat "$env"
  if [ -f index.html ]; then
    if grep "ABUILD_RELEASER_ACTION_INDEX_TEMPLATE" index.html 2> /dev/null; then
      tpl -env @"$env" /index.html.tpl > index.html
    fi
  else
    tpl -env @"$env" /index.html.tpl > index.html
  fi
  rm "$env"
  cd -
}

if [ "$INPUT_GENERATE_INDEX_PAGES" = "true" ]; then
  generate_index . false
  tmp="$(mktemp)"
  find . -mindepth 1 ! -name "$(printf "*\n*")" -type d -not -path '*/.*' > "$tmp"
  while IFS= read -r dir
  do
    generate_index "$dir" true
  done < "$tmp"
  rm "$tmp"
fi

# Add files and push the branch
git add .
git -c user.name="$GITHUB_ACTOR" -c user.email="$GITHUB_ACTOR@users.noreply.github.com" commit -m "${INPUT_COMMIT_MESSAGE:-Update packages}" && \
  git push origin gh-pages || echo Nothing to commit

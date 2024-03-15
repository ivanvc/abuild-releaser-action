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
ORIGINAL_BRANCH="$(git symbolic-ref --short HEAD)"
GH_PAGES_BRANCH=gh-pages

# Checkout gh-pages branch
if ! git fetch -n --no-recurse-submodules --depth=1 origin "$GH_PAGES_BRANCH"; then
  echo "The branch gh-pages doesn't exist."
  exit 1
fi
git checkout --progress --force -B "$GH_PAGES_BRANCH" refs/remotes/origin/"$GH_PAGES_BRANCH"

# Copy current packages.
mkdir ~/packages
find . -type d -maxdepth 1 -mindepth 1 -not -path '*/.*' -exec cp -rf {} ~/packages/ \;
git checkout "$ORIGINAL_BRANCH"

# Build any directory that contains an APKBUILD file
# shellcheck disable=SC2016
for dir in $(echo "$INPUT_PACKAGE_DIRS" | tr ',' '\n'); do
  find "$dir" -type f -name APKBUILD -exec /bin/sh -c 'cd $(dirname {}); abuild -F checksum; abuild -F -r; git clean -dfx' \;
done


# Clean the repository and checkout the gh-pages branch
# Copy released files
git checkout "$GH_PAGES_BRANCH"
cp "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub" .
cp -rf "$HOME"/packages/* .

# Generate index pages
REPO_ROOT=$PWD
generate_index() {
  dir=$1
  add_top_level=$2
  files=$3
  cd "$dir"
  if [ -z "$files" ]; then
    files=$(find . -mindepth 1 -maxdepth 1 ! -name "$(printf "*\n*")" ! -name index.html ! -path '*/.*')
  fi
  env="$(mktemp)"
  template="$REPO_ROOT/$INPUT_INDEX_PAGE_TEMPLATE"
  if [ ! -f "$template" ]; then
    template=/index.html.tpl
  fi
  cat <<EOF > "$env"
title='$GITHUB_REPOSITORY Alpine packages'
add_top_level=$add_top_level
EOF
  for file in $files; do
    if [ -d "$file" ]; then
      echo "files.'$file'.size=0" >> "$env"
    else
      echo "files.'$file'.size=$(git ls-tree --format='%(objectsize)' "$GH_PAGES_BRANCH" "$file")" >> "$env"
    fi
    echo "files.'$file'.created_at='$(git log --follow --format=%ad --date iso-strict "$file" | tail -1)'" >> "$env"
  done
  if "$add_top_level"; then
    echo "dir='$dir'" >> "$env"
  fi
  if [ -f index.html ] && grep "ABUILD_RELEASER_ACTION_INDEX_TEMPLATE" index.html > /dev/null || [ ! -f index.html ]; then
    tpl -toml -env @"$env" "$template" > index.html
  fi
  rm "$env"
  cd -
}
if [ "$INPUT_GENERATE_SINGLE_INDEX_PAGE" = "true" ]; then
  files=$(find . ! -name "$(printf "*\n*")" ! -name index.html ! -path '*/.*' -type f)
  generate_index . false "$files"
elif [ "$INPUT_GENERATE_INDEX_PAGES" = "true" ]; then
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
  git push origin "$GH_PAGES_BRANCH" || echo Nothing to commit
